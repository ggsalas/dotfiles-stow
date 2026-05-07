# Neovim
alias vi='nvim'

# Files and folders
alias ..='cd ..'

# Brew - requires brew installed: https://brew.sh
alias brew-sync='brew bundle install --file=~/dotfiles/setupMac/Brewfile'

# macOS options
alias mac-setup='sh ~/dotfiles/setupMac/macOptions.sh'

# Others
alias reload='source ~/.zshrc'
alias untar='tar -xvf'
alias docker-stop='docker stop $(docker ps -aq)'
alias docker-list='docker ps -aq'
alias t='tmux attach || tmux new -s NoNamedSession'
