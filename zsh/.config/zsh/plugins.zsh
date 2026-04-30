# require install with brew: brew install zoxide
eval "$(zoxide init zsh --cmd cd)"

# require install with brew: brew install mise
mise() {
  unfunction mise
  eval "$(command mise activate zsh)"
  mise "$@"
}
