#!/bin/sh
# Herdr TUI agent picker (works with the sidebar hidden).
# Bound as a [[keys.command]] popup in config.toml. Lists every agent across
# all spaces; the popup closes after picking.
#   n/j: next   p/k: previous   /: filter   enter: go   esc: cancel
herdr="${HERDR_BIN_PATH:-/opt/homebrew/bin/herdr}"
fzf=/opt/homebrew/bin/fzf
. "$(dirname "$0")/colors.sh"

workspaces=$("$herdr" workspace list 2>/dev/null) || exit 0
list=$("$herdr" agent list 2>/dev/null | /usr/bin/jq -r --argjson ws "$workspaces" --arg cur "${HERDR_PANE_ID:-}" \
  --arg cw "$C_WORKING" --arg cb "$C_BLOCKED" --arg cd "$C_DONE" --arg ci "$C_IDLE" --arg cu "$C_UNKNOWN" '
  def glyph:
    if . == "blocked" then "\u001b[\($cb)m●\u001b[0m"
    elif . == "working" then "\u001b[\($cw)m●\u001b[0m"
    elif . == "done" then "\u001b[\($cd)m●\u001b[0m"
    elif . == "idle" then "\u001b[\($ci)m○\u001b[0m"
    else "\u001b[\($cu)m·\u001b[0m" end;
  ($ws.result.workspaces | map({ key: .workspace_id, value: . }) | from_entries) as $byid
  | .result.agents[]
  | ($byid[.workspace_id] // {}) as $w
  | [ .pane_id,
      (if ($cur != "" and .pane_id == $cur) or ($cur == "" and .focused) then "*" else "" end),
      "\(.agent_status | glyph)  \($w.number // "?")  \($w.label // .workspace_id)"
        + "  \u001b[36m\(.agent)\u001b[0m"
        + (if (.terminal_title_stripped // "") != "" then "  \u001b[90m\(.terminal_title_stripped)\u001b[0m" else "" end) ]
  | @tsv')
[ -n "$list" ] || exit 0

# Start on the agent you are in, if any.
pos=$(printf '%s\n' "$list" | /usr/bin/awk -F '\t' '$2 == "*" { print NR; exit }')

sel=$(printf '%s\n' "$list" | "$fzf" \
  --ansi --color "$FZF_COLORS" --delimiter '\t' --with-nth 3 \
  --layout reverse --no-input --no-info --no-separator --border none \
  --pointer '▌' --prompt '/ ' \
  --header 'n/p move · / filter · enter go · esc cancel' \
  --bind "load:pos(${pos:-1})" \
  --bind 'n:down,j:down,p:up,k:up' \
  --bind '/:show-input+unbind(n,j,p,k,/)' \
  | /usr/bin/cut -f1)

[ -n "$sel" ] && "$herdr" agent focus "$sel" >/dev/null
