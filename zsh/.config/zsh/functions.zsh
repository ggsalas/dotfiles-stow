# Make CTRL-Z background things and unbackground them
function fg-bg() {
  if [[ $#BUFFER -eq 0 ]]; then
    fg
  else
    zle push-input
  fi
}

# Kill all processes that use a specific port
function kill-port() {
  port=$1
  kill $(lsof -t -i:${port})
}
