# This... is my DIY plugin manager for Zsh. "Why did I reinvent the wheel yet
# again and created my own plugin manager?" you might ask. Well, some of them
# are too slow (antigen, zplug), some are too complicated (antigen-hs, zplugin)
# and some are too simple (zgen, antibody). So, I decided to go into my cave for
# a couple of weeks and now, I proudly present to you MY ZSH PLUGIN MANAGER
# (ZPLG for short). It is very fast even without caching (that's why it isn't
# implemented), has the most essential features and is not bloated. The code is
# rather complex at the first glance because of two reasons:
#
# 1. The syntax of the shell language, to put it simply, is utter trash designed
#    40 (!!!) years ago.
# 2. The shell language, especially when it comes to Zsh, is rather slow, so I
#    had to use as little abstraction as possible.
#
# But fear not, read my comments and they'll guide you through this jungle of
# shell script mess.

# $ZPLG_HOME is a directory where all your plugins are downloaded. In the future
# it might also contain some kind of state/lock/database files. This variable
# can only be modified before `source`-ing this script.
ZPLG_HOME="${ZPLG_HOME:-${XDG_DATA_HOME:-${HOME}/.local/share}/zplg}"

# Default plugin source, see the `plugin` function for description.
ZPLG_DEFAULT_SOURCE="${ZPLG_DEFAULT_SOURCE:-github}"

# Directory where plugins are stored. It is separate from $ZPLG_HOME for
# compatibility with future versions, in case I decide to put more stuff in
# $ZPLG_HOME later.
ZPLG_PLUGINS_DIR="${ZPLG_PLUGINS_DIR:-${ZPLG_HOME}/plugins}"

# basic logging {{{

  _zplg_log() {
    print >&2 -r -- "${fg_bold[blue]}[zplg]${reset_color} $@"
  }

  _zplg_debug() {
    if [[ -n "$ZPLG_DEBUG" ]]; then
      _zplg_log "${fg[green]}debug:${reset_color} $@"
    fi
  }

  _zplg_error() {
    # try to find the place outside of the script that caused this error
    local i external_caller=''
    for (( i = 1; i <= ${#funcfiletrace[@]}; i++ )); do
      # $funcfiletrace contains file paths and line numbers
      # $functions_source tells in which file a function was defined
      # <-> matches any number
      if [[ "${funcfiletrace[i]}" != "${functions_source[_zplg_error]}":<-> ]]; then
        # $functrace contains "ugly" call sites, where the line numbers are
        # relative to the beginning of a function/file. I use it here only for
        # consistency with the shell.
        external_caller=" at ${functrace[i]}"
        break
      fi
    done
    _zplg_log "${fg[red]}error${external_caller}:${reset_color} $@"
  }

# }}}

# These variables contain essential information about the currently loaded
# plugins. When I say "essential" I mean "required for upgrading,
# reinstallating and uninstalling plugins", so options for configuring loading
# behavior are not stored here.
#
# $ZPLG_LOADED_PLUGINS is an array of plugin IDs (UPDATE: set with IDs as keys
# and installation directories as values), other variables are associative
# arrays that have IDs as their keys. It is implemented this way because you
# can't put associative arrays (or any other alternative to "objects") into
# another associative array.
declare -gA ZPLG_LOADED_PLUGINS
declare -gA ZPLG_LOADED_PLUGIN_URLS ZPLG_LOADED_PLUGIN_SOURCES ZPLG_LOADED_PLUGIN_BUILD_CMDS

# A wrapper around `source` for easier profiling and debugging. You can override
# this function to change the plugin loading strategy.
if ! declare -f _zplg_load &>/dev/null; then
  _zplg_load() { source "$@"; }
fi

autoload -Uz is-at-least

if [[ -z "${reset_color+1}" ]]; then
  autoload -Uz colors && colors
fi

# plugin sources {{{
# See documentation of the `plugin` function for description.

  _zplg_source_url() {
    local action="$1" plugin_url="$2" plugin_dir="$3"
    case "$action" in
      (download|upgrade) wget --timestamping --directory-prefix="$plugin_dir" -- "$plugin_url" ;;
      (*) _zplg_error "unknown action: $action"; return 1 ;;
    esac
  }

  _zplg_source_git() {
    setopt local_options err_return
    local action="$1" plugin_url="$2" plugin_dir="$3"

    # Make a local variable which is exported (-x) into the environment (yes,
    # this is indeed a valid combination).
    local -x GIT_TERMINAL_PROMPT=0
    # From <https://github.com/sindresorhus/pure/blob/89c9e30a38d3d35457bcc58b43ea6c28ae56934b/pure.zsh#L410-L419>
    local -x GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh} -o BatchMode=yes"
    local -x GPG_TTY=''

    case "$action" in
      (download)
        local git_version
        # Get the output of `git --version`, split it into lines, pick the first
        # one, remove the prefix `git version `.
        git_version=${${${(f)"$(git --version)"}[1]}#'git version '}

        local has_partial_clone=''
        # <https://github.blog/open-source/git/highlights-from-git-2-25/>
        if is-at-least 2.25 "$git_version"; then has_partial_clone='yes'; fi

        git clone --progress --recurse-submodules ${has_partial_clone:+'--filter=blob:none'} \
          -- "$plugin_url" "$plugin_dir" ;;

      (upgrade)
        local exit_code=0
        git -C "$plugin_dir" symbolic-ref --quiet HEAD >/dev/null || exit_code=$?

        case "$exit_code" in
          (0) # HEAD points to a branch
            git -C "$plugin_dir" pull ;;
          (1) # HEAD is in a detached state (e.g. a tag is checked out)
            git -C "$plugin_dir" fetch ;;
          (*) # an error has occured
            return exit_code ;;
        esac

        git -C "$plugin_dir" submodule update --init --recursive ;;

      (*) _zplg_error "unknown action: $action"; return 1 ;;
    esac
  }

  _zplg_source_github() {
    local action="$1" plugin_url="$2" plugin_dir="$3"
    _zplg_source_git "$action" "https://github.com/$plugin_url.git" "$plugin_dir"
  }

# }}}

# The main part of my plugin manager. This function does two things: it
# downloads a plugin if necessary and loads it into the shell. Usage is very
# simple:
#
# plugin <id> <url> option_a=value_a option_b=value_b ...
#
# <id>
#   identifier of the plugin, alphanumeric, may contain underscores,
#   hyphens and periods, mustn't start with a period.
#
# <url>
#   I guess this is self-descriptive.
#
# Some options can be repeated (marked with a plus). Available options:
#
# from
#   Sets plugin source. Sources are where the plugin will be downloaded from.
#   Currently supported sources are:
#   * git    - clones a repository
#   * github - clones a repository from GitHub
#   * url    - simply downloads a file
#   Custom sources can be easily created by declaring a function named
#   `_zplg_source_${source_name}`. It should take three arguments: the action
#   (`download` or `upgrade`), plugin URL and plugin directory. It must, well,
#   either download a plugin from the given URL into the given directory, or
#   upgrade an already downloaded plugin inside of the given directory. Please
#   note that neither of these functions is executed INSIDE of the plugin
#   directory (i.e. current working directory is not changed).
#
# build (+)
#   Command which builds/compiles the plugin, executed just once in a subshell
#   within $plugin_dir (i.e. after cd $plugin_dir) after downloading. Plugin
#   directory is accessible through the $plugin_dir variable.
#
# before_load (+) and after_load (+)
#   Execute commands before and after loading of the plugin, useful when you
#   need to read plugin directory which is available through the $plugin_dir
#   variable.
#
# load (+) and ignore (+)
#   Globs which tell what files should be sourced (load) or ignored (ignore).
#   If glob expands to nothing (NULL_GLOB), nothing is loaded.
#
# Neat trick when using options: if you want to assign values using an array,
# write it like this: option=${^array}. That way `option=` is prepended to
# each element of `array`.
#
# For examples see my dotfiles: https://github.com/dmitmel/dotfiles/blob/master/zsh/plugins.zsh
# You may ask me why did I choose to merge loading and downloading behavior
# into one function. Well, first of all plugin manager itself becomes much
# simpler. Second: it allows you to load plugins from any part of zshrc (which
# is useful for me because my dotfiles are used by my friends, and they too
# want customization) and even in an active shell.
#
# Oh, and I had to optimize this function, so it is very long because I merged
# everything into one code block. I hope (this is also a message for my future
# self) that you'll be able to read this code, I tried to comment everything.
plugin() {

  # NOTE: We don't use `setopt local_options` here, so that if a plugin executes
  # `setopt` commands of its own, their effects propagate out of this function.
  # Instead, I track the status of ERR_RETURN manually, to restore it to its
  # original value before returning from this function, but also when actually
  # loading the plugin, since not every plugin may be compatible with the strict
  # behavior of ERR_RETURN.
  if [[ -o err_return ]]; then
    local __zplg_err_return_was_set=1
  else
    local __zplg_err_return_was_set=0
  fi
  setopt err_return

  {

  # parse basic arguments {{{

  if (( $# < 2 )); then
    _zplg_error "usage: $0 <id> <url> [option...]"
    return 1
  fi

  readonly plugin_id="$1" plugin_url="$2"; shift 2

  if [[ -z "$plugin_id" || "$plugin_id" == *[^[a-zA-Z0-9._-]]* || "$plugin_id" == '.'* ]]; then
    _zplg_error "invalid plugin ID"
    return 1
  fi

  if [[ -z "$plugin_url" ]]; then
    _zplg_error "invalid plugin URL"
    return 1
  fi

  # Don't even try to continue if the plugin has already been loaded. Currently,
  # ZPLG can only load plugins, and doesn't bother with reloading or unloading
  # them.
  if (( ${+ZPLG_LOADED_PLUGINS[$plugin_id]} )); then
    _zplg_error "plugin $plugin_id has already been loaded"
    return 1
  fi

  # }}}

  # parse options {{{

  # `${arr:#pat}` filters out all elements from an array which match a given pattern.
  local -a invalid_options=( "${@:#*?=?*}" )
  if (( ${#invalid_options[@]} != 0 )); then
    _zplg_error "options must have the following format: <key>=<value>"
    return 1
  fi
  unset invalid_options

  local plugin_from="$ZPLG_DEFAULT_SOURCE"
  local -a plugin_build plugin_before_load plugin_after_load plugin_load plugin_ignore

  local option key value
  for option in "$@"; do
    # split 'option' at the first occurence of '='
    key="${option%%=*}" value="${option#*=}"
    case "$key" in
      from)
        eval "plugin_$key=\"\$value\"" ;;
      build|before_load|after_load|load|ignore)
        eval "plugin_$key+=(\"\$value\")" ;;
      *)
        _zplg_error "unknown option: $key"
        return 1 ;;
    esac
  done
  unset option key value

  if (( ${#plugin_load[@]} == 0 )); then
    # default loading patterns:
    # - *.plugin.zsh for most plugins and Oh My Zsh ones
    # - *.zsh-theme for most themes and Oh My Zsh ones
    # - init.zsh for Prezto plugins
    # ([1]) means "expand only to the first match"
    plugin_load=("(*.plugin.zsh|*.zsh-theme|init.zsh)([1])")
  fi

  readonly plugin_from plugin_build plugin_before_load plugin_after_load plugin_load plugin_ignore

  # }}}

  # download plugin {{{

  {

    readonly plugin_dir="$ZPLG_PLUGINS_DIR/$plugin_id"
    # simple check whether the plugin directory exists is enough for me
    if [[ ! -d "$plugin_dir" ]]; then
      _zplg_log "downloading $plugin_id"
      _zplg_source_"$plugin_from" download "$plugin_url" "$plugin_dir"

      if (( ${#plugin_build[@]} > 0 )); then
        _zplg_log "building $plugin_id"
        # The flag `-q` tells `cd` to not execute `chpwd` hooks (which get
        # inherited by subshells)
        ( cd -q -- "$plugin_dir" && _zplg_run_commands "${plugin_build[@]}" )
      fi
    fi

  } always {
    if (( $? != 0 )); then
      _zplg_error "an error occured while downloading $plugin_id"
    fi
  }

  # }}}

  # load plugin {{{

  {

    # The list of file paths matched by the `load=...` patterns, excluding those
    # matched by `ignore=...`
    local -a scripts_to_load

    () {
      # Set the NULL_GLOB option, so that patterns that generate no matches
      # don't throw an error. We can't append `(N)` to patterns to get this
      # effect, as they might already have parentheses at the end with their own
      # qualifiers. The reason this code sits in an anonymous function is that
      # here we can use LOCAL_OPTIONS to have Zsh take care of restoring the
      # previous value of NULL_GLOB, as set by the user or by other scripts.
      setopt local_options null_glob

      # ${~var_name} turns on globbing from the expansion of ${var_name}. Note
      # the lack of double quotes -- that is intentional and necessary.
      # ${^array} makes it so that a prefix is prepended to all values of an
      # array (Zsh performs this BEFORE the glob expansion step).
      scripts_to_load=( "${plugin_dir}/"${~^plugin_load} )

      local ignore_pat
      for ignore_pat in "${plugin_ignore[@]}"; do
        # ${array:#pattern} removes all elements matching the pattern from the array
        scripts_to_load=( "${scripts_to_load[@]:#"${plugin_dir}/"${~ignore_pat}}" )
      done
    }

    readonly scripts_to_load

    _zplg_run_commands "${plugin_before_load[@]}"

    if [[ -z "$ZPLG_SKIP_LOADING" ]]; then
      local script_path
      for script_path in "${scripts_to_load[@]}"; do
        _zplg_debug "sourcing $script_path"

        if (( ! __zplg_err_return_was_set )); then
          setopt no_err_return
        fi

        _zplg_load "$script_path"

        if [[ -o err_return ]]; then
          # The plugin has decided to flip ERR_RETURN on for some reason. Well,
          # we'll make sure to propagate this effect to our caller...
          __zplg_err_return_was_set=1
        else
          setopt err_return
        fi
      done
      unset script_path
    fi

    _zplg_run_commands "${plugin_after_load[@]}"

    # plugin has finally been loaded, we can add it to $ZPLG_LOADED_PLUGINS
    ZPLG_LOADED_PLUGINS[$plugin_id]="$plugin_dir"
    ZPLG_LOADED_PLUGIN_URLS[$plugin_id]="$plugin_url"
    ZPLG_LOADED_PLUGIN_SOURCES[$plugin_id]="$plugin_from"

    # HORRIBLE HACK: because you can't store arrays as values in associative
    # arrays, I simply quote every element with the (@q) modifier, then join
    # quoted ones into a string with (j: :) and put this "encoded" string into
    # the associative array. Terrible idea? Maybe. Does it work? YES!!!
    if (( ${#plugin_build[@]} > 0 )); then
      ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]="${(j: :)${(@q-)plugin_build}}"
    fi

  } always {
    if (( $? != 0 )); then
      _zplg_error "an error occured while loading $plugin_id"
    fi
  }

  # }}}

  } always {
    if (( ! __zplg_err_return_was_set )); then
      setopt no_err_return
    fi
  }

}

# Runs a list of commands within the context of an isolated function.
_zplg_run_commands() {
  # (F) modifier joins an array with newlines
  eval "${(F)@}"
}

# helper functions for plugin configuration {{{

  # Simplifies modification of path variables (path/fpath/manpath etc) in
  # after_load and before_load hooks.
  plugin-cfg-path() {
    setopt local_options err_return

    if (( $# < 2 )); then
      _zplg_error "usage: $0 <var_name> prepend|append <value...>"
      return 1
    fi

    if [[ -z "$plugin_dir" ]]; then
      _zplg_error "this function is intended to be used in after_load or before_load hooks"
      return 1
    fi

    local var_name="$1" operator="$2"; shift 2

    if [[ "$var_name" != *path || "${(Pt)var_name}" != array* ]]; then
      _zplg_error "unknown path variable $var_name"
      return 1
    fi

    if [[ "$operator" != (prepend|append) ]]; then
      _zplg_error "unknown operator $operator"
      return 1
    fi

    local value
    for value in "$@"; do
      if [[ "${value:-.}" == "." ]]; then
        value="${plugin_dir}"
      else
        value="${plugin_dir}/${value}"
      fi
      if [[ -z "${${(P)var_name}[(re)${value}]+1}" ]]; then
        case "$operator" in
          prepend) set -A "$var_name" "$value" "${(@P)var_name}" ;;
           append) set -A "$var_name" "${(@P)var_name}" "$value" ;;
        esac
      fi
    done
  }

  plugin-cfg-git-checkout-version() {
    setopt local_options err_return

    if (( $# < 1 )); then
      _zplg_error "usage: $0 <pattern>"
      return 1
    fi

    local pattern="$1" tag="" found=0

    git tag --list --sort=-version:refname | while IFS= read -r tag; do
      if [[ "$tag" == ${~pattern} ]]; then
        found=1
        break
      fi
    done

    if (( found )); then
      _zplg_log "the latest version is $tag"
      git checkout --quiet "refs/tags/$tag"
    fi
  }

# }}}

# Useful commands for managing plugins {{{

  # I chose to make each of these commands as a separate function because:
  # 1. automatic completion
  # 2. automatic correction
  # 3. hyphen is a single keystroke, just like space, so `zplg-list` is not
  #    hard to type fast.

  # Prints IDs of all loaded plugins.
  zplg-list() {
    if (( $# != 0 )); then
      _zplg_error "usage: $0"
      return 1
    fi
    # (k) picks the keys, (F) joins them with newlines
    print -r -- "${(Fk)ZPLG_LOADED_PLUGINS}"
  }

  # Upgrades all plugins if no arguments are given, otherwise upgrades plugins by
  # their IDs.
  zplg-upgrade() {
    setopt local_options err_return

    if (( $# == 0 )); then
      set -- "${(@k)ZPLG_LOADED_PLUGINS}"
    fi

    local plugin_id plugin_url plugin_from plugin_dir exit_code=0
    for plugin_id in "$@"; do
      if (( ! ${+ZPLG_LOADED_PLUGINS[$plugin_id]} )); then
        _zplg_error "unknown plugin $plugin_id"
        return 1
      fi

      plugin_dir="${ZPLG_LOADED_PLUGINS[$plugin_id]}"
      plugin_url="${ZPLG_LOADED_PLUGIN_URLS[$plugin_id]}"
      plugin_from="${ZPLG_LOADED_PLUGIN_SOURCES[$plugin_id]}"

      _zplg_log "upgrading $plugin_id"
      _zplg_source_"$plugin_from" upgrade "$plugin_url" "$plugin_dir" || {
        exit_code=$?; _zplg_error "failed to upgrade $plugin_id"; continue
      }

      zplg-rebuild "$plugin_id" || {
        exit_code=$?; continue
      }
    done

    return exit_code
  }

  # Reinstall plugins by IDs.
  zplg-reinstall() {
    setopt local_options err_return

    if (( $# == 0 )); then
      _zplg_error "usage: $0 <plugin...>"
      return 1
    fi

    local plugin_id plugin_url plugin_from plugin_dir exit_code=0
    for plugin_id in "$@"; do
      if (( ! ${+ZPLG_LOADED_PLUGINS[$plugin_id]} )); then
        _zplg_error "unknown plugin $plugin_id"
        return 1
      fi

      plugin_dir="${ZPLG_LOADED_PLUGINS[$plugin_id]}"
      plugin_url="${ZPLG_LOADED_PLUGIN_URLS[$plugin_id]}"
      plugin_from="${ZPLG_LOADED_PLUGIN_SOURCES[$plugin_id]}"

      _zplg_log "removing $plugin_id"
      rm -rf "$plugin_dir" || {
        exit_code=$?; _zplg_error "failed to remove $plugin_id"; continue
      }

      _zplg_log "downloading $plugin_id"
      _zplg_source_"$plugin_from" download "$plugin_url" "$plugin_dir" || {
        exit_code=$?; _zplg_error "failed to download $plugin_id": continue
      }

      zplg-rebuild "$plugin_id" || {
        exit_code=$?; continue
      }
    done

    return exit_code
  }

  zplg-rebuild() {
    setopt local_options err_return

    if (( $# == 0 )); then
      _zplg_error "usage: $0 <plugin...>"
      return 1
    fi

    local plugin_id exit_code=0
    for plugin_id in "$@"; do
      local plugin_dir="${ZPLG_LOADED_PLUGINS[$plugin_id]}"

      if (( ${+ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]} )); then
        # TERRIBLE HACK continued: this monstrosity is used to "decode" build
        # commands. See ending of the `plugin` function for "encoding"
        # procedure. First, I get encoded string. Then with the (z) modifier I
        # split it into array taking into account quoting. Then with the (Q)
        # modifier I unquote every value.
        local plugin_build_str="${ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]}"
        local plugin_build=("${(@Q)${(z)plugin_build_str}}")

        _zplg_log "building $plugin_id"
        ( cd -q -- "$plugin_dir" && _zplg_run_commands "${plugin_build[@]}" ) || {
          exit_code=$?; _zplg_error "failed to build $plugin_id"; continue
        }
      fi
    done

    return exit_code
  }

  # Clears directories of plugins by their IDs.
  zplg-purge() {
    setopt local_options err_return

    if (( $# == 0 )); then
      _zplg_error "usage: $0 <plugin...>"
      return 1
    fi

    local plugin_id exit_code=0
    for plugin_id in "$@"; do
      if (( ! ${+ZPLG_LOADED_PLUGINS[$plugin_id]} )); then
        _zplg_error "unknown plugin $plugin_id"
        return 1
      fi

      local plugin_dir="${ZPLG_LOADED_PLUGINS[$plugin_id]}"

      _zplg_log "removing $plugin_id"
      rm -rf -- "$plugin_dir" || {
        exit_code=$?; _zplg_error "failed to remove $plugin_id"; continue
      }
    done

    return exit_code
  }

# }}}

# completion for the plugin management commands {{{

  _zplg_plugins() {
    local expl
    _wanted zplg-plugins expl 'plugin ID' compadd "$@" -k - ZPLG_LOADED_PLUGINS
  }

  compdef _zplg_plugins zplg-{upgrade,reinstall,rebuild,purge}

  # This will complete nothing after the `zplg-list` command
  compdef 'compadd -' zplg-list

# }}}
