# To work with git worktrees and tmux
#
# Commands:
# ---------
#   wt <branch-name> [base-branch]  - Create a new worktree + tmux session and switch to it
#   wt-open <branch-name>           - Open (or switch to) a tmux session for an existing worktree
#   wt-clean <branch-name>          - Remove a worktree and its tmux session (warns if unpushed/uncommitted changes)
#   wt-list                         - List all worktrees
#
# Folder structure: 
# -----------------
#   repo-folder/          <-- _wt_root_dir() return this
#     reponame/           <-- main repo
#     worktrees/          <-- $root_dir/worktrees
#       feature-x/
#       fix-bug/

# --- Helpers ---

# Get the repo-folder/ root (parent of the main repo, works from inside a worktree too)
_wt_root_dir() {
  local common_dir
  common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || {
    echo "Not inside a git repository" >&2
    return 1
  }

  # Resolve absolute path
  common_dir="$(cd "$common_dir" && pwd -P)"

  # main repo root = parent of .git
  local repo_root
  repo_root="$(dirname "$common_dir")"

  # repo-folder = parent of repo root
  dirname "$repo_root"
}

# Sanitize branch name for tmux session name (replace / and . with -)
_wt_session_name() {
  local repo_name="$1"
  local branch="$2"
  local sanitized
  sanitized="$(echo -n "$branch" | tr -c '[:alnum:]_-' '-')"
  echo "[${repo_name}] ${sanitized}"
}

# Get the main repo folder name
_wt_repo_name() {
  local common_dir
  common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
  common_dir="$(cd "$common_dir" && pwd -P)"
  basename "$(dirname "$common_dir")"
}

# Open or switch to a tmux session, handling nested tmux correctly
_wt_tmux_open() {
  local session="$1"
  local dir="$2"

  if [ -n "$TMUX" ]; then
    # Already inside tmux: create detached and switch
    tmux new-session -d -s "$session" -c "$dir" 2>/dev/null
    tmux switch-client -t "=$session"
  else
    tmux new-session -s "$session" -c "$dir"
  fi
}

# --- Main functions ---

# Create worktree + tmux session
wt() {
  if [ -z "$1" ]; then
    echo "Usage: wt <branch-name> [base-branch]"
    return 1
  fi

  local name="$1"
  local base="$2"
  local root_dir
  root_dir="$(_wt_root_dir)" || return 1
  local repo_name
  repo_name="$(_wt_repo_name)" || return 1
  local session_name="$(_wt_session_name "$repo_name" "$name")"

  local wt_base="$root_dir/worktrees"
  local wt_dir="$wt_base/$name"

  if [ -d "$wt_dir" ]; then
    echo "Worktree already exists: $wt_dir" >&2
    echo "Use 'wt-open $name' to open it in a tmux session" >&2
    return 1
  fi

  mkdir -p "$wt_base"

  if git show-ref --verify --quiet "refs/heads/$name"; then
    git worktree add "$wt_dir" "$name" || return 1
  else
    if [ -n "$base" ]; then
      git worktree add "$wt_dir" -b "$name" "$base" || return 1
    else
      git worktree add "$wt_dir" -b "$name" || return 1
    fi
  fi

  _wt_tmux_open "$session_name" "$wt_dir"
}

# Open existing worktree session (or attach to it)
wt-open() {
  if [ -z "$1" ]; then
    echo "Usage: wt-open <branch-name>"
    return 1
  fi

  local name="$1"
  local root_dir
  root_dir="$(_wt_root_dir)" || return 1
  local repo_name
  repo_name="$(_wt_repo_name)" || return 1
  local session_name="$(_wt_session_name "$repo_name" "$name")"

  local wt_dir="$root_dir/worktrees/$name"

  if [ ! -d "$wt_dir" ]; then
    echo "Worktree '$name' not found at $wt_dir" >&2
    return 1
  fi

  # Try attaching to existing session, or create a new one in the worktree dir
  if tmux has-session -t "=$session_name" 2>/dev/null; then
    if [ -n "$TMUX" ]; then
      tmux switch-client -t "=$session_name"
    else
      tmux attach -t "=$session_name"
    fi
  else
    _wt_tmux_open "$session_name" "$wt_dir"
  fi
}

# Remove worktree + tmux session
wt-clean() {
  if [ -z "$1" ]; then
    echo "Usage: wt-clean <branch-name>"
    return 1
  fi

  local name="$1"
  local root_dir
  root_dir="$(_wt_root_dir)" || return 1
  local repo_name
  repo_name="$(_wt_repo_name)" || return 1
  local session_name="$(_wt_session_name "$repo_name" "$name")"

  local wt_dir="$root_dir/worktrees/$name"

  if [ ! -d "$wt_dir" ]; then
    echo "Worktree '$name' not found at $wt_dir" >&2
    return 1
  fi

  # Check for uncommitted changes
  local has_uncommitted=false
  local has_unpushed=false
  local warnings=""

  if ! git -C "$wt_dir" diff --quiet 2>/dev/null || \
     ! git -C "$wt_dir" diff --cached --quiet 2>/dev/null || \
     [ -n "$(git -C "$wt_dir" ls-files --others --exclude-standard 2>/dev/null)" ]; then
    has_uncommitted=true
    warnings+="  - Uncommitted changes detected\n"
  fi

  # Check if branch has commits not pushed to any remote
  local branch
  branch="$(git -C "$wt_dir" rev-parse --abbrev-ref HEAD 2>/dev/null)"
  if [ -n "$branch" ]; then
    local upstream
    upstream="$(git -C "$wt_dir" rev-parse --abbrev-ref "@{upstream}" 2>/dev/null)"
    if [ -z "$upstream" ]; then
      has_unpushed=true
      warnings+="  - Branch '$branch' has no remote tracking branch\n"
    elif [ -n "$(git -C "$wt_dir" log "$upstream..HEAD" --oneline 2>/dev/null)" ]; then
      has_unpushed=true
      warnings+="  - Branch '$branch' has unpushed commits\n"
    fi
  fi

  if $has_uncommitted || $has_unpushed; then
    echo "Warning:"
    echo "$warnings"
    echo -n "Remove worktree anyway? (yes/no): "
    read -r answer
    if [ "$answer" != "yes" ]; then
      echo "Aborted."
      return 1
    fi
  fi

  # Move out of the worktree dir if we're inside it, otherwise removal fails
  local real_pwd="$(pwd -P)"
  local real_wt="$(cd "$wt_dir" && pwd -P)"
  if [ "$real_pwd" = "$real_wt" ] || [[ "$real_pwd" == "$real_wt"/* ]]; then
    cd "$root_dir" || return 1
  fi

  # Remove worktree first, then kill tmux session
  git worktree remove --force "$wt_dir" || {
    echo "Failed to remove worktree" >&2
    return 1
  }

  # Kill tmux session if it exists
  tmux kill-session -t "=$session_name" 2>/dev/null
}

# List worktrees
wt-list() {
  git worktree list
}

# --- Completions ---

_wt_branches() {
  local branches
  # List branches from all worktrees (skip the first which is the main repo)
  branches=(${(f)"$(git worktree list --porcelain 2>/dev/null | grep '^branch ' | sed 's|^branch refs/heads/||')"})
  compadd -a branches
}

compdef _wt_branches wt-open wt-clean
