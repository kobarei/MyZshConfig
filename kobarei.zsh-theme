### Segment drawing
# A few utility functions to make it easy and re-usable to draw segmented prompts
CURRENT_BG='NONE'
SEGMENT_SEPARATOR=''

# Begin a segment
# Takes two arguments, background and foreground. Both can be omitted,
# rendering default background/foreground.
prompt_segment() {
  local bg fg
  [[ -n $1 ]] && bg="%K{$1}" || bg="%k"
  [[ -n $2 ]] && fg="%F{$2}" || fg="%f"
  if [[ $CURRENT_BG != 'NONE' && $1 != $CURRENT_BG ]]; then
    echo -n " %{$bg%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR%{$fg%} "
  else
    echo -n "%{$bg%}%{$fg%} "
  fi
  CURRENT_BG=$1
  [[ -n $3 ]] && echo -n $3
}

# End the prompt, closing any open segments
prompt_end() {
  if [[ -n $CURRENT_BG ]]; then
    echo -n " %{%k%F{$CURRENT_BG}%}$SEGMENT_SEPARATOR"
  else
    echo -n "%{%k%}"
  fi
  echo -n "%{%f%}"
  CURRENT_BG=''
}

### Prompt components
# Each component will draw itself, and hide itself if no information needs to be shown

# Context: user@hostname (who am I and where am I)
prompt_context() {
  local user=`whoami`
  if [[ "$user" != "$DEFAULT_USER" || -n "$SSH_CLIENT" ]]; then
    prompt_segment black default "%(!.%{%F{yellow}%}.)%n"
  fi
}

# Git: branch/detached head, dirty status
prompt_git() {
  local ref dirty
  if $(git rev-parse --is-inside-work-tree >/dev/null 2>&1); then
    dirty=$(parse_git_dirty)
    ref=$(git symbolic-ref HEAD 2> /dev/null) || ref="➦ $(git show-ref --head -s --abbrev |head -n1 2> /dev/null)"
    if [[ -n $dirty ]]; then
      prompt_segment yellow black
    else
      prompt_segment green black
    fi
    ZSH_THEME_GIT_PROMPT_ADDED=" ✭"
    ZSH_THEME_GIT_PROMPT_MODIFIED=" ✹"
    ZSH_THEME_GIT_PROMPT_DELETED=" ✖"
    ZSH_THEME_GIT_PROMPT_RENAMED=" ➜"
    ZSH_THEME_GIT_PROMPT_UNMERGED=" ═"
    ZSH_THEME_GIT_PROMPT_UNTRACKED=" ✚"
    echo -n "${ref/refs\/heads\// }$(git_prompt_status)"
  fi
}

# Dir: current working directory
prompt_dir() {
  prompt_segment blue default '%~'
}

# Virtualenv: current working virtualenv
prompt_virtualenv() {
  local virtualenv_path="$VIRTUAL_ENV"
  if [[ -n $virtualenv_path ]]; then
    prompt_segment blue black "(`basename $virtualenv_path`)"
  fi
}

prompt_status() {
  # prompt_segment black default "%*" # clock
  local symbols
  symbols=()
  [[ $UID -eq 0 ]] && symbols+="%{%F{yellow}%}⚡"
  [[ $RETVAL -eq 0 ]] && prompt_segment black default "(・∀・)" && symbols+="%{%F{green}%}✔"
  [[ $RETVAL -ne 0 ]] && prompt_segment black default "('･_･')" && symbols+="%{%F{red}%}✘"
  [[ $(jobs -l | wc -l) -gt 0 ]] && symbols+="%{%F{cyan}%}⚙"
  [[ -n "$symbols" ]] && prompt_segment black default "$symbols"
}

ruby_version() {
  echo "%{$fg[cyan]%}‹$(rbenv version | sed -e "s/ (set.*$//")›"
}

## Main prompt
build_prompt() {
  RETVAL=$?
  prompt_status
  prompt_virtualenv
  prompt_dir
  prompt_git
  prompt_end
}

second() {
  prompt_context
  prompt_segment black default "%{$fg[red]%}$"
  prompt_end
}

PROMPT='$(build_prompt)
$(second) %{$reset_color%}'
RPROMPT='$(ruby_version)[%*]%{$reset_color%}'
SPROMPT="%{${fg[yellow]}%}%r is correct? (*_*) [Yes, No, Abort, Edit]:%{${reset_color}%}"
