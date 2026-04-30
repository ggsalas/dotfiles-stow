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
  port=$@
  kill $(lsof -t -i:${port})
}
