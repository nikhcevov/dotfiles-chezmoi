# dotfiles (chezmoi)

Migrated from the stow layout (shared/ + arch/) of ovchingus/dotfiles.

## Bootstrap a new machine

```
chezmoi init --apply git@github.com:nikhcevov/dotfiles-chezmoi.git
```

First init generates `~/.config/chezmoi/chezmoi.toml` from
`.chezmoi.toml.tmpl`: it asks for the git email (used by `dot_gitconfig.tmpl`,
defaults to the personal one when run non-interactively, e.g. by the Ansible
`dotfiles` role). chezmoi's own config is therefore NOT managed as a dotfile.

**Existing machines:** re-run `chezmoi init` once to get the email prompt
(until then the gitconfig template falls back to the default email).

Fish plugins are installed automatically by
`run_onchange_after_10-install-fisher-plugins.sh.tmpl` (fisher + everything
from `fish_plugins`, re-runs when the list changes). Plugin files themselves
(`conf.d/done.fish`, `conf.d/nvm.fish`, ...) are fisher-owned and deliberately
NOT tracked - add/remove plugins via `fish_plugins` only.

## Daily use

- edit: `chezmoi edit ~/.config/fish/config.fish` (or edit the target file, then `chezmoi re-add`)
- add a new file: `chezmoi add ~/.config/<app>`
- push: `chezmoi cd && git add -A && git commit -m "..." && git push`
- pull on another machine: `chezmoi update`

## Per-host differences

Use templates: rename a file to `<name>.tmpl` and branch on
`{{ .chezmoi.hostname }}` / `{{ .chezmoi.os }}`. Host-wide ignores live
in `.chezmoiignore.tmpl` (KDE/GTK configs are Linux-only).

`fish_variables`, `fish_env` and zsh are deliberately NOT managed:
universal variables and secrets are per-machine state. The login shell
is set to fish by `run_once_after_90-fish-default-shell.sh.tmpl`
(may ask for sudo on first apply).

## KDE Plasma settings

Managed as individual rc-files (kdeglobals, kwinrc, kglobalshortcutsrc,
...), not one big config. Hardware/session state is deliberately NOT
managed: kwinoutputconfig.json (monitor layout), plasma appletsrc,
powermanagementprofilesrc, kwalletrc, kded*, session/.

Plasma rewrites these files at runtime and on logout, so:

- change settings in the GUI, then capture: `chezmoi re-add`
- after pulling changes on the other machine (`chezmoi update`),
  log out/in — otherwise the running session overwrites them on logout
