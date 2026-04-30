# Edit command line inside vim
autoload -U edit-command-line
zle -N edit-command-line
bindkey '^x^x' edit-command-line

# Make CTRL-Z background things and unbackground them
zle -N fg-bg
bindkey '^Z' fg-bg

# Neovim
alias vi='nvim'
alias vit='NVIM_APPNAME=nvim-for-terminal nvim'
alias vi50='NVIM_APPNAME=vi50 nvim'

# Files and folders
alias ..='cd ..'

# Others
alias reload='source ~/.zshrc'
alias untar='tar -xvf'
alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
alias df='dotfiles'

alias docker-stop='docker stop $(docker ps -aq)'
alias docker-list='docker ps -aq'

alias t='tmux attach || tmux new -s Work'

alias emu="~/Library/Android/sdk/emulator/emulator"
