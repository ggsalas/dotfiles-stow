autoload -U colors
autoload -Uz vcs_info

# determine if is git directrory
zstyle ':vcs_info:*' enable git hg
zstyle ':vcs_info:*' check-for-changes true

# git indicators
zstyle ':vcs_info:*' stagedstr "%F{green}● %f"
zstyle ':vcs_info:*' unstagedstr "%F{red}● %f"
zstyle ':vcs_info:*' use-simple true
zstyle ':vcs_info:git+set-message:*' hooks git-untracked

# format git branch + indicators
zstyle ':vcs_info:git*:*' formats '%F{cyan}%b%f %m%c%u '

setopt PROMPT_SUBST
autoload -U add-zsh-hook
add-zsh-hook precmd vcs_info

# Left prompt: ssh + background task if exists
export PS1=" %F{green}${SSH_TTY:+%n@%m}%f%B${SSH_TTY:+:}%b%F{yellow}%B%(1j.○ .)%b%f%B❯%b "


# Right prompt: git + folder (disabled inside neovim terminal)
if [[ -z "$NVIM" ]]; then
  export RPROMPT="\${vcs_info_msg_0_}%F{blue}%~%f "
fi

# 
# helpers
#
function +vi-git-untracked() {
  emulate -L zsh
  if [[ -n $(git ls-files --exclude-standard --others 2> /dev/null) ]]; then
    hook_com[unstaged]+="%F{blue}● %f"
  fi
}

