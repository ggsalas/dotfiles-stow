# require install with brew: brew install zoxide
eval "$(zoxide init zsh --cmd cd)"

# require install with brew: brew install mise
mise() {
  unfunction mise
  eval "$(command mise activate zsh)"
  mise "$@"
}

# fzf completion (lightweight)
[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ] && source /opt/homebrew/opt/fzf/shell/completion.zsh

# fzf key bindings (lazy load on first Ctrl+R or Ctrl+T)
_fzf_load() {
  unfunction _fzf_load
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
}
zle -N _fzf_load
bindkey '^R' _fzf_load
bindkey '^T' _fzf_load
