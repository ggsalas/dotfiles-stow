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

# Herdr app: reload mods after editing them (they sit behind stow symlinks, so
# Herdr doesn't see the change). Switches layout away and back; settings, keys
# and layouts apply by themselves within ~10 s.
herdr-app-reload() {
  local cur other
  cur=$(herdr-app status | sed -n 's/.*"layout": "\(.*\)".*/\1/p')
  [ -n "$cur" ] || { echo "herdr-app is not running"; return 1; }
  [ "$cur" = main ] && other=win98 || other=main
  herdr-app do layout.switch --name "$other" >/dev/null && sleep 1 && herdr-app do layout.switch --name "$cur" >/dev/null
}
