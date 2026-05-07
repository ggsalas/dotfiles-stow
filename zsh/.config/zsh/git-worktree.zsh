# to work with git worktrees
# repo-folder/          <-- _wt_root_dir() return this
#   reponame/           <-- main repo
#   worktrees/          <-- $root_dir/worktrees
#     feature-x/
#     fix-bug/

# --- Helpers ---

# Get the repo-folder/ root (parent of the main repo, works from inside a worktree too)
_wt_root_dir() {
  local common_dir
  common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || {
    echo "Not inside a git repository" >&2
    return 1
  }

  common_dir="$(cd "$common_dir" && pwd -P)"

  local repo_root
  repo_root="$(dirname "$common_dir")"

  dirname "$repo_root"
}

# --- Main functions ---

# Create worktree and cd into it
wt() {
  if [ -z "$1" ]; then
    echo "Usage: wt <branch-name> [base-branch]"
    return 1
  fi

  local name="$1"
  local base="$2"
  local root_dir
  root_dir="$(_wt_root_dir)" || return 1

  local wt_base="$root_dir/worktrees"
  local wt_dir="$wt_base/$name"

  if [ -d "$wt_dir" ]; then
    echo "Worktree already exists: $wt_dir" >&2
    echo "Use 'wt-open $name' to cd into it" >&2
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

  cd "$wt_dir"
}

# cd into an existing worktree
wt-open() {
  if [ -z "$1" ]; then
    echo "Usage: wt-open <branch-name>"
    return 1
  fi

  local name="$1"
  local root_dir
  root_dir="$(_wt_root_dir)" || return 1

  local wt_dir="$root_dir/worktrees/$name"

  if [ ! -d "$wt_dir" ]; then
    echo "Worktree '$name' not found at $wt_dir" >&2
    return 1
  fi

  cd "$wt_dir"
}

# Remove worktree
wt-clean() {
  if [ -z "$1" ]; then
    echo "Usage: wt-clean <branch-name>"
    return 1
  fi

  local name="$1"
  local root_dir
  root_dir="$(_wt_root_dir)" || return 1

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

  # Move out of the worktree dir if we're inside it
  local real_pwd="$(pwd -P)"
  local real_wt="$(cd "$wt_dir" && pwd -P)"
  if [ "$real_pwd" = "$real_wt" ] || [[ "$real_pwd" == "$real_wt"/* ]]; then
    cd "$root_dir" || return 1
  fi

  git worktree remove --force "$wt_dir" || {
    echo "Failed to remove worktree" >&2
    return 1
  }
}

# List worktrees
wt-list() {
  git worktree list
}

# --- Completions ---

_wt_branches() {
  local branches
  branches=(${(f)"$(git worktree list --porcelain 2>/dev/null | grep '^branch ' | sed 's|^branch refs/heads/||')"})
  compadd -a branches
}

compdef _wt_branches wt-open wt-clean
