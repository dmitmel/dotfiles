# This... is my DIY plugin manager for Zsh. "Why did I reinvent the wheel yet
# again and created my own plugin manager?" you might ask. Well, some of them
# are too slow (antigen, zplug), some are too complicated (antigen-hs, zplugin)
# and some are too simple (zgen, antibody). So, I decided to go into into my
# cave for a couple of weeks and now, I proudly present to you MY ZSH PLUGIN
# MANAGER (ZPLG for short). It is very fast even without caching (that's why it
# isn't implemented), has the most essential features and is not bloated. The
# code is rather complex at the first glance because of two reasons:
#
# 1. The syntax of the shell language, to put it simply, utter trash designed
#    40 (!!!) years ago.
# 2. The shell language, especially when it comes to Zsh, is rather slow, so I
#    had to use as little abstraction as possible.
#
# But, read my comments and they'll guide you through this jungle of shell
# script mess.

# Also:
#
# 1. This script is compatitable with SH_WORD_SPLIT (if you for whatever reason
#    want to enable this), so I use "@" everywhere. This expansion modifier
#    means "put all elements of the array in separate quotes".
# 2. I often use the following snippet to exit functions on errors:
#    eval "$some_user_command_that_might_fail" || return "$?"
#    I do this instead of `setopt local_options err_exit` because some plugins
#    may not be compatitable with ERREXIT.

# $ZPLG_HOME is a directory where all your plugins are downloaded, it also
# might contain in the future some kind of state/lock/database files. It is
# recommended to change it before `source`-ing this script because you may end
# up with a broken plugin directory.
ZPLG_HOME="${ZPLG_HOME:-${XDG_DATA_HOME:-${HOME}/.local/share}/zplg}"

# Default plugin source, see the `plugin` function for description.
ZPLG_DEFAULT_SOURCE="${ZPLG_DEFAULT_SOURCE:-github}"

# Directory in which plugins are stored. It is separate from $ZPLG_HOME for
# compatitability with future versions, in case I decide to put more stuff in
# $ZPLG_HOME later.
ZPLG_PLUGINS_DIR="${ZPLG_HOME}/plugins"

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
    local external_caller
    local i; for (( i=1; i<=${#funcfiletrace}; i++ )); do
      # $funcfiletrace contains file paths and line numbers
      # $functions_source tells in which file a function was defined
      if [[ "${funcfiletrace[$i]}" != "${functions_source[_zplg_error]}":* ]]; then
        # $functrace contains "ugly" call sites, the line numbers are
        # relative to the beginning of a function/file here. I use it here
        # only for consistency with the shell, TODO might change this in the
        # future.
        _zplg_log "${fg[red]}error:${reset_color} ${functrace[$i]}: $@"
        return 1
      fi
    done

    # if for whatever reason we couldn't find the caller, simply print the
    # error without it
    _zplg_log "${fg[red]}error:${reset_color} $@"
    return 1
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
typeset -gA ZPLG_LOADED_PLUGINS
typeset -gA ZPLG_LOADED_PLUGIN_URLS ZPLG_LOADED_PLUGIN_SOURCES ZPLG_LOADED_PLUGIN_BUILD_CMDS

# A wrapper around `source` for easier profiling and debugging. You can override
# this function to change the plugin loading strategy.
(( ${+functions[_zplg_load]} )) || function _zplg_load { source "$@"; }

# plugin sources {{{
# See documentation of the `plugin` function for description.

  _zplg_source_url_download() {
    local plugin_url="$1" plugin_dir="$2"
    wget --timestamping --directory-prefix "$plugin_dir" -- "$plugin_url"
  }

  _zplg_source_url_upgrade() {
    _zplg_source_url_download "$@"
  }

  _zplg_source_git_download() {
    local plugin_url="$1" plugin_dir="$2"
    git clone --recurse-submodules -- "$plugin_url" "$plugin_dir"
  }

  _zplg_source_git_upgrade() {
    local plugin_url="$1" dir="$2"
    { git -C "$plugin_dir" pull || git -C "$plugin_dir" fetch } && \
      git -C "$plugin_dir" submodule update --init --recursive
  }

  _zplg_source_github_download() {
    local plugin_url="$1" plugin_dir="$2"
    _zplg_source_git_download "https://github.com/$plugin_url.git" "$plugin_dir"
  }

  _zplg_source_github_upgrade() {
    local plugin_url="$1" plugin_dir="$2"
    _zplg_source_git_upgrade "https://github.com/$plugin_url.git" "$plugin_dir"
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
#   Custom sources can easily be defined. Just create two functions:
#   `_zplg_source_${name}_download` and `_zplg_source_${name}_upgrade`. Both
#   functions take two arguments: plugin URL and plugin directory. Download
#   function must, well, download a plugin from the given URL into the given
#   directory, upgrade one, obviously, upgrades plugin inside of the given
#   directory. Please note that neither of these functions is executed INSIDE
#   of the plugin directory (i.e. current working directory is not changed).
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

  # parse basic arguments {{{

  if (( $# < 2 )); then
    _zplg_error "usage: $0 <id> <url> [option...]"
    return 1
  fi

  local plugin_id="$1" plugin_url="$2"; shift 2

  if [[ ! "$plugin_id" =~ '^[a-zA-Z0-9_\-][a-zA-Z0-9._\-]*$' ]]; then
    _zplg_error "invalid plugin ID"
    return 1
  fi

  if [[ -z "$plugin_url" ]]; then
    _zplg_error "invalid plugin URL"
    return 1
  fi

  # Don't even try to continue if the plugin has already been loaded. This is
  # not or problem. Plugin manager loads plugins and shouldn't bother
  # unloading them.
  if (( ${+ZPLG_LOADED_PLUGINS[$plugin_id]} )); then
    _zplg_error "plugin $plugin_id has already been loaded"
    return 1
  fi

  # }}}

  # parse options {{{

  # `${arr:#pat}` filters out all elements from an array which match a given pattern.
  local -a invalid_options=( "${@:#*?=?*}" )
  if (( ${#invalid_options} != 0 )); then
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

  # }}}

  if (( ${#plugin_load} == 0 )); then
    # default loading patterns:
    # - *.plugin.zsh for most plugins and Oh My Zsh ones
    # - *.zsh-theme for most themes and Oh My Zsh ones
    # - init.zsh for Prezto plugins
    # ([1]) means "expand only to the first match"
    plugin_load=("(*.plugin.zsh|*.zsh-theme|init.zsh)([1])")
  fi

  # download plugin {{{

  local plugin_dir="$ZPLG_PLUGINS_DIR/$plugin_id"
  # simple check whether the plugin directory exists is enough for me
  if [[ ! -d "$plugin_dir" ]]; then
    _zplg_log "downloading $plugin_id"
    _zplg_source_"$plugin_from"_download "$plugin_url" "$plugin_dir" || return "$?"

    if (( ${#plugin_build} > 0 )); then
      _zplg_log "building $plugin_id"
      ( cd "$plugin_dir" && _zplg_run_commands "${plugin_build[@]}" ) || return "$?"
    fi
  fi

  # }}}

  # load plugin {{{

  {

    _zplg_run_commands "${plugin_before_load[@]}" || return "$?"

    local -a reply
    _zplg_expand_load_patterns plugin_load plugin_ignore "$plugin_dir"

    if [[ -z "$ZPLG_SKIP_LOADING" ]]; then
      local script_path
      for script_path in "${reply[@]}"; do
        _zplg_debug "sourcing $script_path"
        _zplg_load "$script_path" || return "$?"
      done
      unset script_path
    fi

    _zplg_run_commands "${plugin_after_load[@]}" || return "$?"

    # plugin has finally been loaded, we can add it to $ZPLG_LOADED_PLUGINS
    ZPLG_LOADED_PLUGINS[$plugin_id]="$plugin_dir"
    ZPLG_LOADED_PLUGIN_URLS[$plugin_id]="$plugin_url"
    ZPLG_LOADED_PLUGIN_SOURCES[$plugin_id]="$plugin_from"

    # HORRIBLE HACK: because you can't store arrays as values in associative
    # arrays, I simply quote every element with the (@q) modifier, then join
    # quoted ones into a string with (j: :) and put this "encoded" string into
    # the associative array. Terrible idea? Maybe. Does it work? YES!!!
    if (( ${#plugin_build} > 0 )); then
      ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]="${(j: :)${(@q+)plugin_build}}"
    fi

  } always {
    if [[ "$?" != 0 ]]; then
      _zplg_error "an error occured while loading $plugin_id"
    fi
  }

  # }}}

}

# Takes the name of a variable with a list of `load=...` patterns, another name
# for a list of `ignore=...` patterns, and a plugin directory relative to which
# these patterns will be evaluated. Returns a list of file paths matched by the
# `load=...` patterns, excluding those matched by `ignore=...`, in the variable
# `$reply` (because shell functions can't return arrays, argh).
_zplg_expand_load_patterns() {
  # Set the option NULL_GLOB so that patterns that generate no matches don't
  # throw an error. This is the only reason for moving this code into a separate
  # function, so that we can use LOCAL_OPTIONS to have Zsh take care of
  # restoring the previous value of NULL_GLOB set by the user or other scripts.
  setopt local_options null_glob

  local load_patterns_var="$1" ignore_patterns_var="$2" plugin_dir="$3"

  # The (P) modifier lets you refer to a variable by a name stored in another variable
  local -a load_patterns=("${(@P)load_patterns_var}")
  # ${~var_name} turns on globbing from the expansion of ${var_name}. Note the
  # lack of double quotes -- that is intentional and necessary. ${^array} makes
  # it so that a prefix is prepended to all values of an array (Zsh performs
  # this BEFORE the glob expansion step).
  reply=( "${plugin_dir}/"${~^load_patterns} )

  local ignore_pat
  for ignore_pat in "${(@P)ignore_patterns_var}"; do
    # ${array:#pattern} removes all elements from the array matching the pattern
    reply=( "${reply[@]:#${plugin_dir}/${~ignore_pat}}" )
  done
}

# Runs a list of commands within the context of an isolated function. Exits
# immediately with an error if any command fails.
_zplg_run_commands() {
  setopt local_options err_exit
  # (F) modifier joins an array with newlines
  eval "${(F)@}"
}

# helper functions for plugin configuration {{{

  # Simplifies modification of path variables (path/fpath/manpath etc) in
  # after_load and before_load hooks.
  plugin-cfg-path() {
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
    if (( $# < 1 )); then
      _zplg_error "usage: $0 <pattern>"
      return 1
    fi

    local pattern="$1" tag="" found=0

    while IFS= read -r tag; do
      if [[ "$tag" == ${~pattern} ]]; then
        found=1
        break
      fi
    done < <(command git tag --sort=-version:refname)

    if (( found )); then
      _zplg_log "the latest version is $tag"
      command git checkout --quiet "$tag"
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
    local plugin_ids_var
    if (( $# > 0 )); then
      plugin_ids_var=("$@")
    else
      plugin_ids_var=("${(k)ZPLG_LOADED_PLUGINS[@]}")
    fi

    local plugin_id plugin_url plugin_from plugin_dir; local -a plugin_build
    for plugin_id in "${plugin_ids_var[@]}"; do
      if (( ! ${+ZPLG_LOADED_PLUGINS[$plugin_id]} )); then
        _zplg_error "unknown plugin $plugin_id"
        return 1
      fi

      plugin_dir="${ZPLG_LOADED_PLUGINS[$plugin_id]}"
      plugin_url="${ZPLG_LOADED_PLUGIN_URLS[$plugin_id]}"
      plugin_from="${ZPLG_LOADED_PLUGIN_SOURCES[$plugin_id]}"

      _zplg_log "upgrading $plugin_id"
      _zplg_source_"$plugin_from"_upgrade "$plugin_url" "$plugin_dir" || return "$?"

      zplg-rebuild "$plugin_id"
    done
  }

  # Reinstall plugins by IDs.
  zplg-reinstall() {
    if (( $# == 0 )); then
      _zplg_error "usage: $0 <plugin...>"
      return 1
    fi

    local plugin_id plugin_url plugin_from plugin_dir; local -a plugin_build
    for plugin_id in "$@"; do
      if (( ! ${+ZPLG_LOADED_PLUGINS[$plugin_id]} )); then
        _zplg_error "unknown plugin $plugin_id"
        return 1
      fi

      plugin_dir="${ZPLG_LOADED_PLUGINS[$plugin_id]}"
      plugin_url="${ZPLG_LOADED_PLUGIN_URLS[$plugin_id]}"
      plugin_from="${ZPLG_LOADED_PLUGIN_SOURCES[$plugin_id]}"

      _zplg_log "removing $plugin_id"
      rm -rf "$plugin_dir"

      _zplg_log "downloading $plugin_id"
      _zplg_source_"$plugin_from"_download "$plugin_url" "$plugin_dir" || return "$?"

      zplg-rebuild "$plugin_id"
    done
  }

  zplg-rebuild() {
    if (( $# == 0 )); then
      _zplg_error "usage: $0 <plugin...>"
      return 1
    fi

    local plugin_id plugin_dir; local -a plugin_build
    for plugin_id in "$@"; do
      plugin_dir="${ZPLG_LOADED_PLUGINS[$plugin_id]}"

      if (( ${+ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]} )); then
        # TERRIBLE HACK continued: this monstrosity is used to "decode" build
        # commands. See ending of the `plugin` function for "encoding"
        # procedure. First, I get encoded string. Then with the (z) modifier I
        # split it into array taking into account quoting. Then with the (Q)
        # modifier I unquote every value.
        plugin_build=("${(@Q)${(z)${ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]}}}")
        _zplg_log "building $plugin_id"
        ( cd "$plugin_dir" && _zplg_run_commands "${plugin_build[@]}" ) || return "$?"
      fi
    done
  }

  # Clears directories of plugins by their IDs.
  zplg-purge() {
    if (( $# == 0 )); then
      _zplg_error "usage: $0 <plugin...>"
      return 1
    fi

    local plugin_id
    for plugin_id in "$@"; do
      if (( ! ${+ZPLG_LOADED_PLUGINS[$plugin_id]} )); then
        _zplg_error "unknown plugin $plugin_id"
        return 1
      fi

      local plugin_dir="${ZPLG_LOADED_PLUGINS[$plugin_id]}"

      _zplg_log "removing $plugin_id"
      rm -rf "$plugin_dir"
    done
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
