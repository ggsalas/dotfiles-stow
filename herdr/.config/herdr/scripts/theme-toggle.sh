#!/bin/bash
# Toggle the Omarchy theme between Everforest Light Hard and Everforest (dark).
# Run by the herdr prefix+t binding. herdr runs it on the server that owns the
# view, so pressing it from the Mac while looking at this machine runs it here.

LIGHT="everforest-light-hard"
DARK="everforest"
LOG="$HOME/.local/state/omarchy/theme-toggle.log"

export PATH="${OMARCHY_PATH:-/usr/share/omarchy}/bin:$PATH"

current=$(cat "$HOME/.local/state/omarchy/current/theme.name" 2>/dev/null)
if [[ $current == "$LIGHT" ]]; then next=$DARK; else next=$LIGHT; fi

# If the herdr server was started outside the desktop (e.g. over SSH), borrow
# the live Hyprland session's environment, like omarchy-theme-set-herdr-machines.
if [[ -z $HYPRLAND_INSTANCE_SIGNATURE ]]; then
  export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
  instance=$(hyprctl instances -j 2>/dev/null | jq -r 'max_by(.time) // empty | "\(.instance) \(.wl_socket)"')
  if [[ -z $instance ]]; then
    echo "$(date '+%F %T') no Hyprland session" >>"$LOG"
    exit 1
  fi
  read -r HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY <<<"$instance"
  export HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
fi

echo "$(date '+%F %T') $current -> $next" >>"$LOG"
omarchy-theme-set "$next" >>"$LOG" 2>&1
