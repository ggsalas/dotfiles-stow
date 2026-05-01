# Edit command line on $EDITOR
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^x^x' edit-command-line

# Make CTRL-Z background things and unbackground them
zle -N fg-bg
bindkey '^Z' fg-bg
