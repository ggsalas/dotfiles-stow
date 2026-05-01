# dotfiles

## Instructions

### 1. Install git, stow and brew

**git** — comes pre-installed on macOS. If not, it will prompt you to install Xcode Command Line Tools:

```sh
git --version
```

**brew** — package manager for macOS:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**stow** — symlink manager used to link dotfiles to `$HOME`:

```sh
brew install stow
```

### 2. Clone the repo and link dotfiles

```sh
git clone https://github.com/ggsalas/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow .
```

`stow .` creates symlinks from each config folder into `$HOME`, based on the `.stowrc` target setting.

### 3. Install brew packages

```sh
brew-sync
```

`brew-sync` runs `brew bundle` and installs all packages defined in `setupMac/Brewfile`. Safe to run multiple times.

### 4. Configure macOS

```sh
mac-setup
```

---

## Short Manuals

### mise — runtime version manager

```sh
mise use node@22          # set Node version for current project
mise use --global node@22 # set Node version globally
mise ls                   # list installed runtimes
mise ls-remote node       # list available Node versions
mise install              # install versions defined in .mise.toml
mise exec -- node index.js # run command with mise-managed runtime
```

### tmux — terminal multiplexer

Prefix key: `Ctrl+Space`

```sh
tmux attach || tmux new -s Work  # attach or create session (alias: t)
```

| Key              | Action                        |
| ---------------- | ----------------------------- |
| `prefix + h`     | split pane horizontally       |
| `prefix + v`     | split pane vertically         |
| `prefix + x`     | kill pane                     |
| `prefix + c`     | new window                    |
| `prefix + k`     | kill window                   |
| `prefix + r`     | rename window                 |
| `prefix + R`     | rename session                |
| `prefix + K`     | kill session                  |
| `Ctrl+S+H/J/K/L` | navigate panes                |
| `Ctrl+S+I/O`     | previous/next window          |
| `Ctrl+S+,/.`     | swap window left/right        |
| `Ctrl+S+Z`       | zoom pane                     |
| `Ctrl+Z`         | background/foreground process |

### zoxide — smarter cd

Configured so all `cd` commands use zoxide ranking automatically. Just use `cd` as usual.

```sh
cd foo        # zoxide automatically ranks foo based on frecency
cd -          # jump to previous directory (via zoxide)
cdi           # interactive fuzzy search with fzf
```

### delta — git diff viewer

Configured as the default git pager — all `git diff`, `git log` and `git show` output goes through delta automatically.

```sh
delta file1 file2   # diff two files outside of git
```

### fzf — fuzzy finder

```sh
Ctrl+R        # fuzzy search command history
Ctrl+T        # fuzzy search files in current dir
Alt+C         # fuzzy cd into subdirectory
**<Tab>        # fuzzy completion for paths, e.g: vim **<Tab>
```

### neovim

Leader key: `Space`

**Navigation**

| Key            | Action                          |
| -------------- | ------------------------------- |
| `h/j/k/l`      | move left/down/up/right         |
| `Ctrl+h/j/k/l` | navigate between windows        |
| `Shift+l/h`    | next/previous tab               |
| `<leader>1-0`  | jump to tab 1-10                |
| `Ctrl+u/d`     | half-page scroll + center       |
| `-`            | open directory (dirvish)        |
| `h/l`          | go up/into directory in dirvish |
| `<leader>f`    | find git files (telescope)      |
| `<leader>s`    | live grep                       |
| `<leader>j`    | buffer list                     |
| `<leader>*`    | grep word under cursor          |

**LSP**

| Key          | Action                                   |
| ------------ | ---------------------------------------- |
| `gd`         | go to definition                         |
| `gr`         | go to references                         |
| `gi`         | go to implementation                     |
| `K`          | hover documentation                      |
| `<leader>rn` | rename symbol                            |
| `<leader>ca` | code action                              |
| `<leader>r`  | replace word under cursor (with confirm) |
| `<leader>,`  | format buffer                            |
| `[e/]e`      | previous/next diagnostic                 |

**Git**

| Key          | Action                                        |
| ------------ | --------------------------------------------- |
| `G`          | git status — interactive (Fugitive)           |
| `dd`         | diff a single file (inside git status buffer) |
| `<leader>gf` | git status (telescope)                        |
| `<leader>gd` | diff all changed files vs base branch         |
| `]c/[c`      | next/previous hunk                            |
| `<leader>ca` | stage hunk                                    |
| `<leader>cd` | reset hunk                                    |
| `<leader>cb` | blame line                                    |

**Search & Replace**

| Key          | Action                                       |
| ------------ | -------------------------------------------- |
| `<leader>S`  | open Spectre (project-wide search & replace) |
| `<leader>Sw` | search word under cursor in Spectre          |

**Terminal**

| Key           | Action                             |
| ------------- | ---------------------------------- |
| `<leader>.`   | run current file in terminal split |
| `<leader>tes` | horizontal terminal split          |
| `<leader>tev` | vertical terminal split            |
| `Ctrl+Esc`    | exit terminal mode                 |
| `gq`          | close terminal buffer              |

**Clipboard**

| Key          | Action                                            |
| ------------ | ------------------------------------------------- |
| `y`          | yank to system clipboard                          |
| `<leader>yf` | copy file path to clipboard, and line if selected |
| `gp`         | go to previously pasted text                      |

### git aliases

| Alias     | Command       | Description              |
| --------- | ------------- | ------------------------ |
| `git lg`  | log --graph   | visual branch graph      |
| `git ls`  | log --pretty  | compact log with dates   |
| `git ll`  | log --numstat | log with file changes    |
| `git lb`  | reflog        | last 10 visited branches |
| `git st`  | status -s     | short status             |
| `git co`  | commit -m     | commit with message      |
| `git ch`  | checkout      |                          |
| `git cp`  | cherry-pick   |                          |
| `git dt`  | difftool      | open diff in nvim        |
| `git wt`  | worktree      |                          |
| `git wtl` | worktree list |                          |
