#!/bin/sh
# Herdr TUI space picker (works with the sidebar hidden).
# Bound as a [[keys.command]] popup in config.toml. Lists only workspaces,
# like the sidebar; the popup closes after picking.
#   n/j: next   p/k: previous   /: filter   enter: go   esc: cancel
#
# Row:  N  ●  space: main-repo         branch ● ● ●
#   agent circle: colors as in the Herdr sidebar (see colors.sh)
#   git dots (as in zsh prompt): green staged, red unstaged, blue untracked
herdr="${HERDR_BIN_PATH:-/opt/homebrew/bin/herdr}"
fzf=/opt/homebrew/bin/fzf
git=/usr/bin/git
tab=$(printf '\t')
. "$(dirname "$0")/colors.sh"

workspaces=$("$herdr" workspace list 2>/dev/null) || exit 0
panes=$("$herdr" pane list 2>/dev/null)
[ -n "$panes" ] || panes='{}'

# id, current, number, agent status, label, main repo (worktrees), folder
rows=$(printf '%s' "$workspaces" | /usr/bin/jq -r --argjson panes "$panes" --arg cur "${HERDR_WORKSPACE_ID:-}" '
  .result.workspaces[]
  | .workspace_id as $id
  | [ $id,
      (if ($cur != "" and $id == $cur) or ($cur == "" and .focused) then "*" else "-" end),
      .number, (.agent_status // "unknown"), .label,
      (if .worktree.is_linked_worktree then .worktree.repo_name else "-" end),
      (.worktree.checkout_path
        // ([$panes.result.panes[]? | select(.workspace_id == $id) | .cwd // empty][0])
        // "-") ]
  | @tsv')
[ -n "$rows" ] || exit 0

# Append git info: branch, staged, unstaged, untracked.
rows=$(printf '%s\n' "$rows" | while IFS="$tab" read -r id cur num st label repo dir; do
  branch=- staged=0 unstaged=0 untracked=0
  if [ "$dir" != "-" ] && "$git" -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    branch=$("$git" -C "$dir" branch --show-current 2>/dev/null)
    [ -n "$branch" ] || branch=$("$git" -C "$dir" rev-parse --short HEAD 2>/dev/null)
    set -- $("$git" --no-optional-locks -C "$dir" status --porcelain 2>/dev/null | /usr/bin/awk '
      /^\?\?/ { u = 1; next }
      { if (substr($0, 1, 1) != " ") s = 1; if (substr($0, 2, 1) != " ") m = 1 }
      END { print s + 0, m + 0, u + 0 }')
    staged=$1 unstaged=$2 untracked=$3
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$id" "$cur" "$num" "$st" "$label" "$repo" "$branch" "$staged" "$unstaged" "$untracked"
done)

# Format: left column padded to the longest "space: repo", then the git column.
list=$(printf '%s\n' "$rows" | /usr/bin/awk -F '\t' \
  -v cw="$C_WORKING" -v cb="$C_BLOCKED" -v cd="$C_DONE" -v ci="$C_IDLE" -v cu="$C_UNKNOWN" '
  BEGIN {
    e = sprintf("%c", 27); R = e "[0m"; DIM = e "[90m"; CY = e "[36m"
    RED = e "[31m"; YEL = e "[33m"; GRN = e "[32m"; BLU = e "[34m"
    AW = e "[" cw "m"; AB = e "[" cb "m"; AD = e "[" cd "m"; AI = e "[" ci "m"; AU = e "[" cu "m"
  }
  { n++; for (i = 1; i <= NF; i++) f[n, i] = $i
    w = length($5) + ($6 != "-" ? length($6) + 2 : 0); if (w > max) max = w }
  END {
    for (r = 1; r <= n; r++) {
      st = f[r, 4]
      dot = st == "blocked" ? AB "●" R : st == "working" ? AW "●" R : st == "done" ? AD "●" R : st == "idle" ? AI "○" R : AU "·" R
      name = f[r, 5]; w = length(name)
      if (f[r, 6] != "-") { name = name DIM ": " f[r, 6] R; w += length(f[r, 6]) + 2 }
      pad = sprintf("%" (max - w + 4) "s", "")
      git = ""
      if (f[r, 7] != "-") {
        git = CY " " f[r, 7] R
        if (f[r, 8]) git = git " " GRN "●" R
        if (f[r, 9]) git = git " " RED "●" R
        if (f[r, 10]) git = git " " BLU "●" R
      }
      printf "%s\t%s\t%s  %s  %s%s%s\n", f[r, 1], f[r, 2], f[r, 3], dot, name, pad, git
    }
  }')

# Start on the current workspace.
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

[ -n "$sel" ] && "$herdr" workspace focus "$sel" >/dev/null
