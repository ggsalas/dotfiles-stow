#!/bin/sh
# Herdr TUI tab bar entry: "[workspace] - host", or "[workspace]: repo - host"
# when the workspace is a linked git worktree.
# Tab-bar command entries get HERDR_ACTIVE_WORKSPACE_ID (the client's workspace);
# fall back to the server-focused one.
herdr="${HERDR_BIN_PATH:-/opt/homebrew/bin/herdr}"
"$herdr" workspace list 2>/dev/null | /usr/bin/jq -r \
  --arg id "${HERDR_ACTIVE_WORKSPACE_ID:-}" \
  --arg host "$(/bin/hostname)" '
  .result.workspaces[]
  | select(if $id != "" then .workspace_id == $id else .focused end)
  | "[\(.label)]"
    + (if .worktree.is_linked_worktree then ": \(.worktree.repo_name)" else "" end)
    + " - \($host)"'
