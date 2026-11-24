#!/bin/sh
# Herdr TUI agent picker (works with the sidebar hidden).
# Bound as a [[keys.command]] popup in config.toml. Lists every agent across
# all spaces on this machine and every saved SSH machine (see machines.sh),
# with the machine name on each row; the popup closes after picking.
#   n/j: next   p/k: previous   /: filter   enter: go   esc: cancel
herdr="${HERDR_BIN_PATH:-/opt/homebrew/bin/herdr}"
fzf=/opt/homebrew/bin/fzf
tab=$(printf '\t')
. "$(dirname "$0")/colors.sh"
. "$(dirname "$0")/machines.sh"

data=$(machines_fetch "workspace list" "agent list")
list=$(printf '%s' "$data" | /usr/bin/jq -r --arg cur "${HERDR_PANE_ID:-}" \
  --arg cw "$C_WORKING" --arg cb "$C_BLOCKED" --arg cd "$C_DONE" --arg ci "$C_IDLE" --arg cu "$C_UNKNOWN" '
  def glyph:
    if . == "blocked" then "\u001b[\($cb)m●\u001b[0m"
    elif . == "working" then "\u001b[\($cw)m●\u001b[0m"
    elif . == "done" then "\u001b[\($cd)m●\u001b[0m"
    elif . == "idle" then "\u001b[\($ci)m○\u001b[0m"
    else "\u001b[\($cu)m·\u001b[0m" end;
  (map(.machine | length) | max // 0) as $mw
  | .[]
  | .sel as $sel | .machine as $m
  | (.r[0].result.workspaces // [] | map({ key: .workspace_id, value: . }) | from_entries) as $byid
  | .r[1].result.agents[]?
  | ($byid[.workspace_id] // {}) as $w
  | [ (if $sel == "" then "-" else $sel end), .pane_id,
      (if $sel == "" and (($cur != "" and .pane_id == $cur) or ($cur == "" and .focused)) then "*" else "" end),
      "\(.agent_status | glyph)  \u001b[90m\($m + " " * ($mw - ($m | length)))\u001b[0m"
        + "  \($w.number // "?")  \($w.label // .workspace_id)"
        + "  \u001b[36m\(.agent)\u001b[0m"
        + (if (.terminal_title_stripped // "") != "" then "  \u001b[90m\(.terminal_title_stripped)\u001b[0m" else "" end) ]
  | @tsv')
[ -n "$list" ] || exit 0

# Start on the agent you are in, if any.
pos=$(printf '%s\n' "$list" | /usr/bin/awk -F '\t' '$3 == "*" { print NR; exit }')

sel=$(printf '%s\n' "$list" | "$fzf" \
  --ansi --color "$FZF_COLORS" --delimiter '\t' --with-nth 4 \
  --layout reverse --no-input --no-info --no-separator --border none \
  --pointer '▌' --prompt '/ ' \
  --header 'n/p move · / filter · enter go · esc cancel' \
  --bind "load:pos(${pos:-1})" \
  --bind 'n:down,j:down,p:up,k:up' \
  --bind '/:show-input+unbind(n,j,p,k,/)' \
  | /usr/bin/cut -f1,2)

[ -n "$sel" ] || exit 0
machine=${sel%%"$tab"*} id=${sel#*"$tab"}
[ "$machine" = - ] && machine=
machines_focus "$machine" agent "$id"
