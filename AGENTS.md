# Dotfiles

One folder per app, linked into `$HOME` with GNU stow (`stow <app>`). Each folder mirrors `$HOME`.

## herdr-app

Only my config is here (`keys.json`, `settings.json`, `layouts/`, `mods/`, `themes/`), symlinked
into `~/.config/herdr-app/`, which stays a real folder where Herdr keeps its state. Never add state
(`data/`, `telemetry/`, ...) to git. Herdr's manual is `~/.config/herdr-app/AGENTS.md`: read it before editing.

Herdr doesn't see changes behind symlinks. `settings.json`, `keys.json` and layouts apply on their
own in ~10 s; **mods don't**. After editing a mod, reload with:

```sh
herdr-app do layout.switch --name win98 && sleep 1 && herdr-app do layout.switch --name everforest-zen
```

(Interactive zsh has `herdr-app-reload`; agents' shells don't, so use the command.) Then check
`herdr-app status` shows no `errors`.
