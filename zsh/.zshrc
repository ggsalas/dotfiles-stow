source ~/.config/zsh/env.zsh
source ~/.config/zsh/functions.zsh

# aliases and bindings depend on functions.zsh, keep them after
source ~/.config/zsh/aliases.zsh
source ~/.config/zsh/bindings.zsh
source ~/.config/zsh/plugins.zsh
source ~/.config/zsh/prompt.zsh
source ~/.config/zsh/git-worktree-tmux.zsh

# Private config (if it exists)
[[ -f ~/.config/zsh/private.zsh ]] && source ~/.config/zsh/private.zsh
