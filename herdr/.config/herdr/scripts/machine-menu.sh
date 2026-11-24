#!/bin/sh
# Herdr TUI machine menu, so the `herdr machine` / ssh-copy-id commands don't
# have to be remembered. Bound as a [[keys.command]] popup in config.toml.
#   add:       authorize your SSH key if needed, then `herdr machine add`
#   copy key:  ssh-copy-id your public key to a host (asks for its password once)
#   reconnect: `herdr machine reconnect` a saved machine
#   status:    `herdr machine status`
#   remove:    `herdr machine remove` a saved machine (remote sessions keep running)
# Hosts are picked from Tailscale peers; type a name to use any other SSH target.
herdr="${HERDR_BIN_PATH:-/opt/homebrew/bin/herdr}"
fzf=/opt/homebrew/bin/fzf
tailscale=/usr/local/bin/tailscale
pubkey="$HOME/.ssh/id_rsa.pub"
. "$(dirname "$0")/colors.sh"

pick() { # header; reads choices on stdin, prints the chosen line
  "$fzf" --ansi --color "$FZF_COLORS" --delimiter '\t' --with-nth 1 \
    --layout reverse --no-info --no-separator --border none \
    --pointer '▌' --prompt '/ ' --header "$1" \
    --bind 'ctrl-n:down,ctrl-p:up'
}

done_wait() {
  printf '\n\033[90mPress enter to close\033[0m'
  read -r _
  exit "${1:-0}"
}

# SSH target: Tailscale peer (shown as "user@host") or whatever you type.
pick_target() {
  peers=$("$tailscale" status --json 2>/dev/null | /usr/bin/jq -r \
    '.Peer[]? | select(.Online) | .DNSName | split(".")[0] | ascii_downcase' 2>/dev/null)
  sel=$(printf '%s\n' $peers | /usr/bin/sed "s/^/$USER@/" | "$fzf" \
    --color "$FZF_COLORS" --layout reverse --no-info --no-separator --border none \
    --pointer '▌' --prompt 'user@host: ' --print-query \
    --header 'Tailscale peers · type another target · enter select · esc cancel' \
    | /usr/bin/tail -1)
  [ -n "$sel" ] || return 1
  printf '%s' "$sel"
}

# Saved machine: prints its id.
pick_machine() {
  list=$("$herdr" machine list 2>/dev/null)
  [ -n "$list" ] || return 1
  printf '%s\n' "$list" | /usr/bin/awk -F '\t' '{ printf "%s  \033[90m%s  %s\033[0m\t%s\n", $2, $3, $5, $1 }' \
    | pick 'enter select · esc cancel' | /usr/bin/cut -f2
}

key_works() { /usr/bin/ssh -o BatchMode=yes -o ConnectTimeout=5 "$1" true 2>/dev/null; }

copy_key() {
  if key_works "$1"; then
    echo "$1 already accepts your SSH key."
  else
    echo "Copying $pubkey to $1 (it will ask for that machine's password)..."
    /usr/bin/ssh-copy-id -i "$pubkey" "$1" || return 1
    key_works "$1" && echo "OK: $1 now accepts your SSH key." || { echo "Key copied but login still fails."; return 1; }
  fi
}

action=$(printf '%s\n' \
  "Add machine	add" \
  "Copy SSH key to a machine	copy" \
  "Reconnect machine	reconnect" \
  "Machine status	status" \
  "Remove machine	remove" \
  | pick 'machines · enter select · esc cancel' | /usr/bin/cut -f2)

case "$action" in
  add)
    target=$(pick_target) || exit 0
    copy_key "$target" || done_wait 1
    printf 'Label for %s (enter = default): ' "$target"
    read -r label
    if [ -n "$label" ]; then "$herdr" machine add "$target" --label "$label"
    else "$herdr" machine add "$target"; fi
    done_wait $? ;;
  copy)
    target=$(pick_target) || exit 0
    copy_key "$target"
    done_wait $? ;;
  reconnect)
    id=$(pick_machine) || { echo "No saved machines."; done_wait 1; }
    [ -n "$id" ] || exit 0
    "$herdr" machine reconnect "$id"
    done_wait $? ;;
  status)
    "$herdr" machine status
    done_wait $? ;;
  remove)
    id=$(pick_machine) || { echo "No saved machines."; done_wait 1; }
    [ -n "$id" ] || exit 0
    "$herdr" machine remove "$id"
    done_wait $? ;;
esac
