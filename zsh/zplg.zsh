#!/usr/bin/env zsh

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
#    had to use as less abstractions as possible.
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


_ZPLG_SCRIPT_PATH="${(%):-%N}"


# $ZPLG_HOME is a directory where all your plugins are downloaded, it also
# might contain in the future some kind of state/lock/database files. It is
# recommended to change it before `source`-ing this script because you may end
# up with a broken plugin directory.
if [[ -z "$ZPLG_HOME" ]]; then
  ZPLG_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zplg"
fi

# Default plugin source, see the `plugin` function for description.
if [[ -z "$ZPLG_DEFAULT_SOURCE" ]]; then
  ZPLG_DEFAULT_SOURCE="github"
fi

# Directory in which plugins are stored. It is separate from $ZPLG_HOME for
# compatitability with future versions.
_ZPLG_PLUGINS_DIR="$ZPLG_HOME/plugins"

# basic logging {{{

  _zplg_log() {
    print >&2 "${fg_bold[blue]}[zplg]${reset_color} $@"
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
      if [[ "${funcfiletrace[$i]}" != "$_ZPLG_SCRIPT_PATH"* ]]; then
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
# $ZPLG_LOADED_PLUGINS is an array of plugin IDs, other variables are
# associative arrays that have IDs as their keys. It is implemented this way
# because you can't put associative arrays (or any other alternative to
# "objects") into another associative array.
typeset -a ZPLG_LOADED_PLUGINS
typeset -A ZPLG_LOADED_PLUGIN_URLS ZPLG_LOADED_PLUGIN_SOURCES ZPLG_LOADED_PLUGIN_BUILD_CMDS

# Takes name of a variable with an array (array is passed by variable name
# because this reduces boilerplate) and runs every command in it, exits
# immediately with an error code if any command fails. This snippet was
# extracted in a function because it's often used to run plugin loading hooks
# (before_load/after_load) or build commands.
_zplg_run_commands() {
  local var_name="$1"
  # (P) modifier lets you access the variable dynamically by its name stored in
  # another variable
  local cmd; for cmd in "${(@P)var_name}"; do
    eval "$cmd" || return "$?"
  done
}

# Expands a glob pattern with the NULL_GLOB flag from the first argument and
# puts all matched filenames into a variable from the second argument because
# shell functions can't return arrays. This function is needed to simplify
# handling of user-provided glob expressions because I can use LOCAL_OPTIONS
# inside a function which reverts NULL_GLOB to its previous value as soon as
# the function returns.
_zplg_expand_pattern() {
  setopt local_options null_glob
  local pattern="$1" out_var_name="$2"
  # ${~var_name} turns on globbing for this expansion, note lack of quotes: as
  # it turns out glob expansions are automatically quoted by design, and when
  # you explicitly write `"${~pattern}"` it is basically the same as
  # `"$pattern"`
  eval "$out_var_name=(\${~pattern})"
}

# Wrapper around `source` for simpler profiling and debugging. You can override
# this function to change plugin loading strategy
_zplg_load() {
  local script_path="$1"
  source "$script_path"
}

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
    local plugin_url="$1" plugin_dir="$2"
    ( cd "$plugin_dir" && git pull && git submodule update --init --recursive )
  }

  # small helper for the git source
  plugin-git-checkout-latest-version() {
    local latest_tag
    git tag --list --sort -version:refname | read -r latest_tag
    if (( ${#tags} == 0 )); then
      _zplg_error "$0: no tags in the Git repository"
      return 1
    fi
    # git checkout
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
#   I guess this is self-descreptive.
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
#   directory, ugrade one, obviously, upgrades plugin inside of the given
#   directory. Please note that neither of these functions is executed INSIDE
#   of the plugin directory (i.e. current working directory is not changed).
#
# build (+)
#   Command which builds/compiles the plugin, executed INSIDE of $plugin_dir
#   (i.e. cd $plugin_dir) once after downloading. Plugin directory can be
#   accessed through the $plugin_dir variable.
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

  local plugin_id="$1"
  local plugin_url="$2"
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
  if _zplg_is_plugin_loaded "$plugin_id"; then
    _zplg_error "plugin $plugin_id has already been loaded"
    return 1
  fi

  # }}}

  # parse options {{{

  local plugin_from="$ZPLG_DEFAULT_SOURCE"
  local -a plugin_build plugin_before_load plugin_after_load plugin_load plugin_ignore

  local option key value; shift 2; for option in "$@"; do
    # globs are faster than regular expressions
    if [[ "$option" != *?=?* ]]; then
      _zplg_error "options must have the following format: <key>=<value>"
      return 1
    fi

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
  done; unset option key value

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

  local plugin_dir="$_ZPLG_PLUGINS_DIR/$plugin_id"
  # simple check whether the plugin directory exists is enough for me
  if [[ ! -d "$plugin_dir" ]]; then
    _zplg_log "downloading $plugin_id"
    _zplg_source_"$plugin_from"_download "$plugin_url" "$plugin_dir" || return "$?"

    if (( ${#plugin_build} > 0 )); then
      _zplg_log "building $plugin_id"
      ( cd "$plugin_dir" && _zplg_run_commands plugin_build ) || return "$?"
    fi
  fi

  # }}}

  # load plugin {{{

  {

    _zplg_run_commands plugin_before_load || return "$?"

    local load_pattern ignore_pattern script_path; local -a script_paths
    for load_pattern in "${plugin_load[@]}"; do
      _zplg_expand_pattern "$plugin_dir/$load_pattern" script_paths
      for script_path in "${script_paths[@]}"; do
        for ignore_pattern in "${plugin_ignore[@]}"; do
          if [[ "$script_path" == "$plugin_dir/"${~ignore_pattern} ]]; then
            # continue outer loop
            continue 2
          fi
        done
        _zplg_debug "sourcing $script_path"
        if [[ -z "$ZPLG_SKIP_LOADING" ]]; then
          _zplg_load "$script_path" || return "$?"
        fi
      done
    done; unset load_pattern ignore_pattern script_path

    _zplg_run_commands plugin_after_load || return "$?"

    # plugin has finally been loaded, we can add it to $ZPLG_LOADED_PLUGINS
    ZPLG_LOADED_PLUGINS+=("$plugin_id")
    ZPLG_LOADED_PLUGIN_URLS[$plugin_id]="$plugin_url"
    ZPLG_LOADED_PLUGIN_SOURCES[$plugin_id]="$plugin_from"

    # HORRIBLE HACK: because you can't store arrays as values in associative
    # arrays, I simply quote every element with the (@q) modifier, then join
    # quoted ones into a string and put this "encoded" string into the
    # associative array. Terrible idea? Maybe. Does it work? YES!!!
    if (( ${#plugin_build} > 0 )); then
      # extra ${...} is needed to turn array into a string by joining it with
      # spaces
      ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]="${${(@q)plugin_build}}"
    fi

  } always {
    if [[ "$?" != 0 ]]; then
      _zplg_error "an error occured while loading $plugin_id"
    fi
  }

  # }}}

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

    local var_name="$1" operator="$2"; shift 2; local values=("$@")

    if [[ "$var_name" != *path || "${(Pt)var_name}" != array* ]]; then
      _zplg_error "unknown path variable $var_name"
      return 1
    fi

    case "$operator" in
      prepend) eval "$var_name=(\"\$plugin_dir/\"\${^values} \${$var_name[@]})" ;;
       append) eval "$var_name=(\${$var_name[@]} \"\$plugin_dir/\"\${^values})" ;;
            *) _zplg_error "unknown $0 operator $operator"
    esac
  }

  plugin-cfg-git-checkout-version() {
    if (( $# < 1 )); then
      _zplg_error "usage: $0 <pattern>"
      return 1
    fi

    local pattern="$1" tag no_tags=1

    command git tag --sort=-version:refname | while IFS= read -r tag; do
      no_tags=0
      if [[ "$tag" == ${~pattern} ]]; then
        break
      fi
    done

    if (( ! no_tags )); then
      _zplg_log "the latest version is $tag"
      command git checkout --quiet "$tag"
    fi
  }

# }}}

# Exits with success code 0 if the plugin is loaded, otherwise exits with error
# code 1. To be used in `if` statements.
_zplg_is_plugin_loaded() {
  local plugin_id="$1"
  # (ie) are subscript flags:
  # - i returns index of the value (reverse subscripting) in the square
  #   brackets (subscript)
  # - e disables patterns matching, so plain string matching is used instead
  # unlike normal programming languages, if the value is not found an index
  # greater than the length of the array is returned
  (( ${ZPLG_LOADED_PLUGINS[(ie)$plugin_id]} <= ${#ZPLG_LOADED_PLUGINS} ))
}

# Useful commands for managing plugins {{{

  # I chose to make each of these commands as a separate function because:
  # 1. automatic completion
  # 2. automatic correction
  # 3. hyphen is a single keystroke, just like space, so `zplg-list` is not
  #    hard to type fast.

  # Prints IDs of all loaded plugins.
  zplg-list() {
    # (F) modifier joins an array with newlines
    print "${(F)ZPLG_LOADED_PLUGINS}"
  }

  # Upgrades all plugins if no arguments are given, otherwise upgrades plugins by
  # their IDs.
  zplg-upgrade() {
    local plugin_ids_var
    if (( $# > 0 )); then
      plugin_ids_var="@"
    else
      plugin_ids_var="ZPLG_LOADED_PLUGINS"
    fi

    local plugin_id plugin_url plugin_from plugin_dir; local -a plugin_build
    # for description of the (P) modifier see `_zplg_run_commands`
    for plugin_id in "${(@P)plugin_ids_var}"; do
      if ! _zplg_is_plugin_loaded "$plugin_id"; then
        _zplg_error "unknown plugin $plugin_id"
        return 1
      fi

      plugin_url="${ZPLG_LOADED_PLUGIN_URLS[$plugin_id]}"
      plugin_from="${ZPLG_LOADED_PLUGIN_SOURCES[$plugin_id]}"
      plugin_dir="$_ZPLG_PLUGINS_DIR/$plugin_id"

      _zplg_log "upgrading $plugin_id"
      _zplg_source_"$plugin_from"_upgrade "$plugin_url" "$plugin_dir" || return "$?"

      if (( ${+ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]} )); then
        # TERRIBLE HACK continued: this monstrosity is used to "decode" build
        # commands. See ending of the `plugin` function for "encoding" procedure.
        # First, I get encoded string. Then with the (z) modifier I split it into
        # array taking into account quoting. Then with the (Q) modifier I unquote
        # every value.
        plugin_build=("${(@Q)${(z)${ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]}}}")
        _zplg_log "building $plugin_id"
        ( cd "$plugin_dir" && _zplg_run_commands plugin_build ) || return "$?"
      fi
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
      if ! _zplg_is_plugin_loaded "$plugin_id"; then
        _zplg_error "unknown plugin $plugin_id"
        return 1
      fi

      plugin_url="${ZPLG_LOADED_PLUGIN_URLS[$plugin_id]}"
      plugin_from="${ZPLG_LOADED_PLUGIN_SOURCES[$plugin_id]}"
      plugin_dir="$_ZPLG_PLUGINS_DIR/$plugin_id"

      _zplg_log "removing $plugin_id"
      rm -rf "$plugin_dir"

      _zplg_log "downloading $plugin_id"
      _zplg_source_"$plugin_from"_download "$plugin_url" "$plugin_dir" || return "$?"

      if (( ${+ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]} )); then
        # for description of this terrible hack see the ending of the
        # `zplg-upgrade` function
        plugin_build=("${(@Q)${(z)${ZPLG_LOADED_PLUGIN_BUILD_CMDS[$plugin_id]}}}")
        _zplg_log "building $plugin_id"
        ( cd "$plugin_dir" && _zplg_run_commands plugin_build ) || return "$?"
      fi
    done
  }

  # Clears directories of plugins by their IDs.
  zplg-purge() {
    if (( $# == 0 )); then
      _zplg_error "usage: $0 <plugin...>"
      return 1
    fi

    for plugin_id in "$@"; do
      if ! _zplg_is_plugin_loaded "$plugin_id"; then
        _zplg_error "unknown plugin $plugin_id"
        return 1
      fi

      local plugin_dir="$_ZPLG_PLUGINS_DIR/$plugin_id"

      _zplg_log "removing $plugin_id"
      rm -rf "$plugin_dir"
    done
  }

# }}}
