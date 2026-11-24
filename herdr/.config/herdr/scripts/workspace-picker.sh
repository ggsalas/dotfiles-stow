#!/bin/sh
# Herdr TUI space picker (works with the sidebar hidden).
# Bound as a [[keys.command]] popup in config.toml. Lists only workspaces,
# like the sidebar, on this machine and every saved SSH machine (see
# machines.sh); the popup closes after picking.
#   n/j: next   p/k: previous   /: filter   enter: go   esc: cancel
#
# Row:  Machine  N  ●  space: main-repo         branch ● ● ●
#   agent circle: colors as in the Herdr sidebar (see colors.sh)
#   git dots (as in zsh prompt): green staged, red unstaged, blue untracked
#   git info for remote machines comes over one SSH call per machine
herdr="${HERDR_BIN_PATH:-/opt/homebrew/bin/herdr}"
fzf=/opt/homebrew/bin/fzf
git=/usr/bin/git
tab=$(printf '\t')
. "$(dirname "$0")/colors.sh"
. "$(dirname "$0")/machines.sh"

data=$(machines_fetch "workspace list" "pane list")

# machine selector ("-" = here), machine, id, current, number, agent status,
# label, main repo (worktrees), folder (on that machine)
rows=$(printf '%s' "$data" | /usr/bin/jq -r --arg cur "${HERDR_WORKSPACE_ID:-}" '
  .[]
  | .sel as $sel | .machine as $m | .r[1] as $panes
  | .r[0].result.workspaces[]?
  | .workspace_id as $id
  | [ (if $sel == "" then "-" else $sel end), $m, $id,
      (if $sel == "" and (($cur != "" and $id == $cur) or ($cur == "" and .focused)) then "*" else "-" end),
      .number, (.agent_status // "unknown"), .label,
      (if .worktree.is_linked_worktree then .worktree.repo_name else "-" end),
      (.worktree.checkout_path
        // ([$panes.result.panes[]? | select(.workspace_id == $id) | .cwd // empty][0])
        // "-") ]
  | @tsv')
[ -n "$rows" ] || exit 0

# Git info per folder: "dir<TAB>branch<TAB>staged<TAB>unstaged<TAB>untracked".
# Runs as a POSIX sh script, here or on the remote machine over one SSH call.
git_script() { # folders, one per line, as $1
  printf '%s\n' 'while IFS= read -r d; do
  b=- s=0 m=0 u=0
  if git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    b=$(git -C "$d" branch --show-current 2>/dev/null)
    [ -n "$b" ] || b=$(git -C "$d" rev-parse --short HEAD 2>/dev/null)
    set -- $(git --no-optional-locks -C "$d" status --porcelain 2>/dev/null | awk '"'"'
      /^\?\?/ { u = 1; next }
      { if (substr($0, 1, 1) != " ") s = 1; if (substr($0, 2, 1) != " ") m = 1 }
      END { print s + 0, m + 0, u + 0 }'"'"')
    s=$1 m=$2 u=$3
  fi
  printf "%s\t%s\t%s\t%s\t%s\n" "$d" "${b:--}" "$s" "$m" "$u"
done <<"HERDR_DIRS_EOF"'
  printf '%s\n' "$1" HERDR_DIRS_EOF
}

gitdir=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/herdr-git.XXXXXX") || exit 1
trap '/bin/rm -rf "$gitdir"' EXIT
printf '%s' "$data" | /usr/bin/jq -r '.[] | [(if .sel == "" then "-" else .sel end), (if .target == "" then "-" else .target end)] | @tsv' \
  | { while IFS="$tab" read -r msel target; do
    dirs=$(printf '%s\n' "$rows" | /usr/bin/awk -F '\t' -v s="$msel" '$1 == s && $9 != "-" { print $9 }' | /usr/bin/sort -u)
    [ -n "$dirs" ] || continue
    out="$gitdir/$(printf '%s' "$msel" | /usr/bin/tr -c 'A-Za-z0-9' _)"
    if [ "$msel" = - ]; then
      git_script "$dirs" | PATH="/usr/bin:/bin:$PATH" /bin/sh > "$out" 2>/dev/null &
    else
      git_script "$dirs" | /usr/bin/ssh -o BatchMode=yes -o ConnectTimeout=3 "$target" sh -s \
        > "$out" 2>/dev/null &
    fi
    printf '%s' "$msel" > "$out.sel"
  done; wait; }

# Join git info onto the rows: ... folder -> branch, staged, unstaged, untracked.
rows=$( { for f in "$gitdir"/*.sel; do
            [ -e "$f" ] || continue
            /usr/bin/awk -v s="$(cat "$f")" '{ print s "\t" $0 }' "${f%.sel}"
          done; printf '%s\n' '--rows--'; printf '%s\n' "$rows"; } \
  | /usr/bin/awk -F '\t' -v OFS='\t' '
    $0 == "--rows--" { rows = 1; next }
    !rows { g[$1 SUBSEP $2] = $3 OFS $4 OFS $5 OFS $6; next }
    { k = $1 SUBSEP $9; $9 = (k in g) ? g[k] : "-" OFS 0 OFS 0 OFS 0; print }')

# Format: machine column, then the left column padded to the longest
# "space: repo", then the git column.
list=$(printf '%s\n' "$rows" | /usr/bin/awk -F '\t' \
  -v cw="$C_WORKING" -v cb="$C_BLOCKED" -v cd="$C_DONE" -v ci="$C_IDLE" -v cu="$C_UNKNOWN" '
  BEGIN {
    e = sprintf("%c", 27); R = e "[0m"; DIM = e "[90m"; CY = e "[36m"
    RED = e "[31m"; YEL = e "[33m"; GRN = e "[32m"; BLU = e "[34m"
    AW = e "[" cw "m"; AB = e "[" cb "m"; AD = e "[" cd "m"; AI = e "[" ci "m"; AU = e "[" cu "m"
  }
  { n++; for (i = 1; i <= NF; i++) f[n, i] = $i
    if (length($2) > mmax) mmax = length($2)
    w = length($7) + ($8 != "-" ? length($8) + 2 : 0); if (w > max) max = w }
  END {
    for (r = 1; r <= n; r++) {
      st = f[r, 6]
      dot = st == "blocked" ? AB "●" R : st == "working" ? AW "●" R : st == "done" ? AD "●" R : st == "idle" ? AI "○" R : AU "·" R
      mach = DIM sprintf("%-" mmax "s", f[r, 2]) R
      name = f[r, 7]; w = length(name)
      if (f[r, 8] != "-") { name = name DIM ": " f[r, 8] R; w += length(f[r, 8]) + 2 }
      pad = sprintf("%" (max - w + 4) "s", "")
      git = ""
      if (f[r, 9] != "-") {
        git = CY " " f[r, 9] R
        if (f[r, 10]) git = git " " GRN "●" R
        if (f[r, 11]) git = git " " RED "●" R
        if (f[r, 12]) git = git " " BLU "●" R
      }
      printf "%s\t%s\t%s\t%s  %s  %s  %s%s%s\n", f[r, 1], f[r, 3], f[r, 4], mach, f[r, 5], dot, name, pad, git
    }
  }')

# Start on the current workspace.
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
machines_focus "$machine" workspace "$id"
