# dotfiles (chezmoi)

Migrated from the stow layout (shared/ + arch/) of ovchingus/dotfiles.

## Bootstrap a new machine

```
chezmoi init --apply git@github.com:ovchingus/dotfiles-chezmoi.git
```

On Ansible-managed workstations this is done by the `dotfiles` role.

## Daily use

- edit: `chezmoi edit ~/.config/fish/config.fish` (or edit the target file, then `chezmoi re-add`)
- add a new file: `chezmoi add ~/.config/<app>`
- push: `chezmoi cd && git add -A && git commit -m "..." && git push`
- pull on another machine: `chezmoi update`

## Per-host differences

Use templates: rename a file to `<name>.tmpl` and branch on
`{{ .chezmoi.hostname }}` / `{{ .chezmoi.os }}`. Host-wide ignores live
in `.chezmoiignore.tmpl` (e.g. ghostty is Linux-only).
