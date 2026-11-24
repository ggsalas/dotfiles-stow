# Fetch herdr API output from this machine and every enabled saved SSH machine
# (`herdr machine list`), in parallel. Sourced by the pickers; needs $herdr.
#
#   machines_fetch "workspace list" "agent list"
#
# Prints one JSON array, one entry per reachable machine:
#   [{ "sel": "",   "machine": "Local",   "target": "",      "r": [<workspace list>, <agent list>] },
#    { "sel": "<id>", "machine": "Omarchy", "target": "omarchy", "r": [...] }]
# `sel` is the --machine selector ("" = this machine), `target` its SSH target. A machine that fails or
# takes longer than $MACHINES_TIMEOUT seconds is left out.
MACHINES_LOCAL_LABEL="${MACHINES_LOCAL_LABEL:-Local}"
MACHINES_TIMEOUT="${MACHINES_TIMEOUT:-3}"

machines_fetch() {
  _mdir=$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/herdr-machines.XXXXXX") || return 1
  # selector<TAB>label<TAB>ssh target, local first ("-": empty fields would
  # be dropped by read, since tab is IFS whitespace).
  { printf -- '-\t%s\t-\n' "$MACHINES_LOCAL_LABEL"
    "$herdr" machine list --json 2>/dev/null \
      | /usr/bin/jq -r '.[]? | select(.enabled) | [.id, .label, .target] | @tsv' 2>/dev/null
  } > "$_mdir/list"

  _mi=0
  while IFS="$(printf '\t')" read -r _msel _mlabel _mtarget; do
    [ "$_msel" = - ] && _msel=
    _mi=$((_mi + 1)); _md="$_mdir/$_mi"; /bin/mkdir "$_md"
    [ "$_mtarget" = - ] && _mtarget=
    printf '%s' "$_msel" > "$_md/sel"; printf '%s' "$_mlabel" > "$_md/label"
    printf '%s' "$_mtarget" > "$_md/target"
    (
      _mj=0
      for _mcmd in "$@"; do
        _mj=$((_mj + 1))
        if [ -n "$_msel" ]; then
          # shellcheck disable=SC2086 # split the subcommand on purpose
          /usr/bin/perl -e 'alarm shift; exec @ARGV' "$MACHINES_TIMEOUT" \
            "$herdr" --machine "$_msel" $_mcmd > "$_md/$_mj.json" 2>/dev/null || exit 1
        else
          # shellcheck disable=SC2086
          "$herdr" $_mcmd > "$_md/$_mj.json" 2>/dev/null || exit 1
        fi
      done
      : > "$_md/ok"
    ) &
  done < "$_mdir/list"
  wait

  for _md in "$_mdir"/*/; do
    [ -f "$_md/ok" ] || continue
    /usr/bin/jq -s --rawfile sel "$_md/sel" --rawfile m "$_md/label" --rawfile t "$_md/target" \
      '{ sel: $sel, machine: $m, target: $t, r: . }' "$_md"/[0-9]*.json 2>/dev/null
  done | /usr/bin/jq -s 'sort_by(.sel != "")'
  /bin/rm -rf "$_mdir"
}

# Focus a picked workspace/agent. On another machine this focuses it on that
# machine's server; switch to the machine in the Herdr TUI to see it.
#   machines_focus <selector> workspace|agent <id>
machines_focus() {
  if [ -n "$1" ]; then "$herdr" --machine "$1" "$2" focus "$3" >/dev/null
  else "$herdr" "$2" focus "$3" >/dev/null; fi
}
