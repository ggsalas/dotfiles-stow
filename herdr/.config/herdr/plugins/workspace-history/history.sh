#!/bin/sh
# Workspace history, like a browser's: every focus is recorded (dropping the
# "forward" part once you go somewhere new); back/forward move through it and
# skip workspaces that were closed.
#   history.sh record | back | forward
# State in $HERDR_PLUGIN_STATE_DIR:
#   list     focused workspace ids, oldest first (at most $MAX)
#   index    line of the current one
#   pending  id that back/forward just focused, so record doesn't push it
herdr="${HERDR_BIN_PATH:-herdr}"
state="${HERDR_PLUGIN_STATE_DIR:?}"
list="$state/list" index="$state/index" pending="$state/pending"
MAX=50

# Serialize: focus events and key presses may run concurrently.
lock="$state/lock"
n=0
until /bin/mkdir "$lock" 2>/dev/null; do
  n=$((n + 1)); [ $n -gt 50 ] && /bin/rm -rf "$lock"; sleep 0.02
done
trap '/bin/rm -rf "$lock"' EXIT

[ -f "$list" ] || : > "$list"
count=$(wc -l < "$list" | tr -d ' ')
cur=$(cat "$index" 2>/dev/null); cur=${cur:-$count}

record() {
  id=${HERDR_WORKSPACE_ID:-}
  [ -n "$id" ] || id=$(printf '%s' "${HERDR_PLUGIN_EVENT_JSON:-}" \
    | jq -r '[.. | .workspace_id? // empty][0] // empty' 2>/dev/null)
  [ -n "$id" ] || return 0
  if [ "$(cat "$pending" 2>/dev/null)" = "$id" ]; then
    rm -f "$pending"
    return 0
  fi
  rm -f "$pending"
  [ "$(sed -n "${cur}p" "$list")" = "$id" ] && return 0
  { [ "$cur" -gt 0 ] && head -n "$cur" "$list"; printf '%s\n' "$id"; } | tail -n "$MAX" > "$list.tmp"
  mv "$list.tmp" "$list"
  wc -l < "$list" | tr -d ' ' > "$index"
}

move() { # step: -1 back, 1 forward
  open=$("$herdr" workspace list 2>/dev/null | jq -r '.result.workspaces[]?.workspace_id')
  here=$(sed -n "${cur}p" "$list")
  i=$((cur + $1))
  while [ $i -ge 1 ] && [ $i -le "$count" ]; do
    id=$(sed -n "${i}p" "$list")
    if [ "$id" != "$here" ] && printf '%s\n' "$open" | grep -qxF "$id"; then
      printf '%s' "$id" > "$pending"
      printf '%s\n' "$i" > "$index"
      "$herdr" workspace focus "$id" >/dev/null 2>&1 || rm -f "$pending"
      return 0
    fi
    i=$((i + $1))
  done
}

case "$1" in
  record) record ;;
  back) move -1 ;;
  forward) move 1 ;;
esac
