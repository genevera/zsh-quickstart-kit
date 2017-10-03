# Copyright 2006-2017 Joseph Block <jpb@apesseekingknowledge.net>
#
# BSD licensed, see LICENSE.txt

# Set this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
export COMPLETION_WAITING_DOTS="true"

# Correct spelling for commands
setopt correct

# turn off the infernal correctall for filenames
unsetopt correctall

source ${HOME}/.path_candidates


# Yes, these are a pain to customize. Fortunately, Geoff Greer made an online
# tool that makes it easy to customize your color scheme and keep them in sync
# across Linux and OS X/*BSD at http://geoff.greer.fm/lscolors/

export LSCOLORS='Exfxcxdxbxegedabagacad'
export LS_COLORS='di=1;34;40:ln=35;40:so=32;40:pi=33;40:ex=31;40:bd=34;46:cd=34;43:su=0;41:sg=0;46:tw=0;42:ow=0;43:'

zstyle ':omz:plugins:ssh-agent' agent-forwarding on

# start zgen
if [ -f ~/.zgen-setup ]; then
  source ~/.zgen-setup
fi
# end zgen

# set some history options
setopt append_history

setopt extended_history
setopt hist_expire_dups_first
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_verify

# Share your history across all your terminal windows
setopt share_history
#setopt noclobber

# set some pushd options
setopt auto_pushd
setopt pushd_ignore_dups
setopt pushd_silent
setopt pushd_to_home

# completion options
setopt auto_list
setopt auto_menu
setopt auto_param_keys
setopt complete_aliases
setopt list_ambiguous
setopt list_types
setopt long_list_jobs



# Keep a ton of history.
HISTSIZE=100000
SAVEHIST=100000
HISTFILE=~/.zsh_history
export HISTIGNORE="ls:cd:cd -:pwd:exit:date:* --help"

# Long running processes should return time after they complete. Specified
# in seconds.
REPORTTIME=2
TIMEFMT="%U user %S system %P cpu %*Es total"

# How often to check for an update. If you want to override this, the
# easiest way is to add a script fragment in ~/.zshrc.d that unsets

# QUICKSTART_KIT_REFRESH_IN_DAYS.
QUICKSTART_KIT_REFRESH_IN_DAYS=7

# Expand aliases inline - see http://blog.patshead.com/2012/11/automatically-expaning-zsh-global-aliases---simplified.html
globalias() {
   if [[ $LBUFFER =~ ' [A-Z0-9]+$' ]]; then
     zle _expand_alias
     zle expand-word
   fi
   zle self-insert
}

zle -N globalias

bindkey " " globalias
bindkey "^ " magic-space           # control-space to bypass completion
bindkey -M isearch " " magic-space # normal space during searches

export LOCATE_PATH=/var/db/locate.database

# Load AWS credentials
if [ -f ~/.aws/aws_variables ]; then
  source ~/.aws/aws_variables
fi

# JAVA setup - needed for iam-* tools
if [ -d /Library/Java/Home ];then
  export JAVA_HOME=/Library/Java/Home
fi

# Speed up autocomplete, force prefix mapping
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)*==34=34}:${(s.:.)LS_COLORS}")';

# Load any custom zsh completions we've installed
if [ -d ~/.zsh-completions ]; then
  for completion in ~/.zsh-completions/*
  do
    source "$completion"
  done

fi

# echo "Current SSH Keys:"
# ssh-add -l

# Make it easy to append your own customizations that override the above by
# loading all files from .zshrc.d directory
[[ ! -d ${HOME}/.zshrc.d ]] && mkdir -p ~/.zshrc.d

if [ -d "${HOME}/.zshrc.d" ]; then
  for dotfile in ~/.zshrc.d/*
  do
    if [ -r "${dotfile}" ]; then
      source "${dotfile}"
    fi
  done
fi

# In case a plugin adds a redundant path entry, remove duplicate entries
# from PATH
#
# This snippet is from Mislav Marohnić <mislav.marohnic@gmail.com>'s
# dotfiles repo at https://github.com/mislav/dotfiles

dedupe_path() {
  typeset -a paths result
  paths=($path)

  while [[ ${#paths} -gt 0 ]]; do
    p="${paths[1]}"
    shift paths
    [[ -z ${paths[(r)$p]} ]] && result+="$p"
  done

  export PATH=${(j+:+)result}
}

# ZSH_THEME="base16_dracula"
dedupe_path
# Do selfupdate checking. We do this after processing ~/.zshrc.d to make the
# refresh check interval easier to customize.
#
# If they unset QUICKSTART_KIT_REFRESH_IN_DAYS in one of the fragments
# in ~/.zshrc.d, then we don't do any selfupdate checking at all.

_load-lastupdate-from-file() {
  local now=$(date +%s)
  if [[ -f "${1}" ]]; then
    local last_update=$(cat "${1}")

  else
    local last_update=0
  fi
  local interval="$(( ${now} - ${last_update} ))"
  echo "${interval}"
}

_update-zsh-quickstart() {
  if [[ ! -L ~/.zshrc ]]; then
    echo ".zshrc is not a symlink, skipping zsh-quickstart-kit update"
  else
    local _link_loc=$(readlink ~/.zshrc);
    if [[ "${_link_loc/${HOME}}" == "${_link_loc}" ]] then
      pushd $(dirname "${HOME}/$(readlink ~/.zshrc)");
    else
      pushd $(dirname ${_link_loc});
    fi;
      local gitroot=$(git rev-parse --show-toplevel)
      if [[ -f "${gitroot}/.gitignore" ]]; then
        if [[ $(grep -c zsh-quickstart-kit "${gitroot}/.gitignore") -ne 0 ]]; then
          echo "---- updating ----"
          git pull
          date +%s >! ~/.zsh-quickstart-last-update
        fi
      else
        echo 'No quickstart marker found, is your quickstart a valid git checkout?'
      fi
    popd
  fi
}



_check-for-zsh-quickstart-update() {
  local day_seconds=$(( 24 * 60 * 60))
  local refresh_seconds=$(( ${day_seconds} * ${QUICKSTART_KIT_REFRESH_IN_DAYS:-7} ))
  local last_quickstart_update=$(_load-lastupdate-from-file ~/.zsh-quickstart-last-update)

  if [ ${last_quickstart_update} -gt ${refresh_seconds} ]; then
    echo "It has been $(( ${last_quickstart_update} / ${day_seconds} )) days since your zsh quickstart kit was updated"
    echo "Checking for zsh-quickstart-kit updates..."
    _update-zsh-quickstart
  fi
}

if [[ ! -z "$QUICKSTART_KIT_REFRESH_IN_DAYS" ]]; then
  _check-for-zsh-quickstart-update
  unset QUICKSTART_KIT_REFRESH_IN_DAYS
fi
