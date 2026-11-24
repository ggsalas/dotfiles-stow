#!/bin/sh
# Herdr native workspace navigator with the sidebar shown only while picking.
# Bound as a [[keys.command]] shell command (prefix+j) in config.toml.
#
# Herdr has no API for the sidebar (it is client state), so this types the
# keys into the frontmost terminal with osascript (macOS needs Accessibility
# permission for the terminal app; it asks the first time):
#   1. if the sidebar is hidden: toggle_sidebar (ctrl+shift+;)
#   2. workspace_picker (prefix+w): j/k or arrows move, enter go, esc cancel
#   3. in the background, once the workspace or machine changes, toggle the
#      sidebar again. After esc (nothing changes) it stays open; it gives up
#      after $WATCH_SECONDS.
# The native navigator also lists the workspaces of other machines.
herdr="${HERDR_BIN_PATH:-/opt/homebrew/bin/herdr}"
jq=/usr/bin/jq
WATCH_SECONDS=120

# Keys, as configured in config.toml ([keys] prefix, toggle_sidebar, and the
# default workspace_picker = prefix+w). macOS key codes: 49 space, 13 w, 41 ;
toggle_sidebar() {
  /usr/bin/osascript -e 'tell application "System Events" to key code 41 using {control down, shift down}'
}
open_navigator() {
  /usr/bin/osascript \
    -e 'tell application "System Events" to key code 49 using {control down}' \
    -e 'delay 0.05' \
    -e 'tell application "System Events" to key code 13'
}

# The client saves the sidebar state in local-<FNV-1a 64 of its socket path>.json
# (herdr src/client/shell/preferences.rs). No "sidebar_collapsed": expanded.
sock_dir=$(/usr/bin/dirname "${HERDR_SOCKET_PATH:-$HOME/.config/herdr/herdr.sock}")
prefs="$HOME/.local/state/herdr/client-shell/local-$(/usr/bin/python3 -c '
import sys
h = 0xcbf29ce484222325
for b in sys.argv[1].encode(): h = ((h ^ b) * 0x100000001b3) & 0xFFFFFFFFFFFFFFFF
print("%016x" % h)' "$sock_dir/herdr-client.sock").json"
sidebar_hidden() { [ "$("$jq" -r '.sidebar_collapsed // false' "$prefs" 2>/dev/null)" = true ]; }

# What changes when a workspace is picked: the selected machine and the
# focused workspace on it.
state() {
  machine=$("$herdr" machine list --json 2>/dev/null | "$jq" -r '[.[] | select(.selected) | .id][0] // ""')
  if [ -n "$machine" ]; then
    ws=$("$herdr" --machine "$machine" workspace list 2>/dev/null)
  else
    ws=$("$herdr" workspace list 2>/dev/null)
  fi
  printf '%s %s' "$machine" "$(printf '%s' "$ws" | "$jq" -r '[.result.workspaces[]? | select(.focused) | .workspace_id][0] // ""')"
}

if ! sidebar_hidden; then
  open_navigator
  exit 0
fi

before=$(state)
toggle_sidebar
/bin/sleep 0.1
open_navigator

i=0
while [ $i -lt $((WATCH_SECONDS * 4)) ]; do
  /bin/sleep 0.25
  i=$((i + 1))
  sidebar_hidden && exit 0 # closed by hand
  if [ "$(state)" != "$before" ]; then
    toggle_sidebar
    exit 0
  fi
done
