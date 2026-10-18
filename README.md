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

Before capturing live changes, review `chezmoi diff`; after capturing them,
run `chezmoi verify` to check that the managed files match.

If working in a separate Git checkout, chezmoi still uses its configured
source directory (check with `chezmoi source-path`). From the checkout root,
target that checkout explicitly:

```sh
chezmoi --source "$PWD" diff
chezmoi --source "$PWD" re-add
chezmoi --source "$PWD" verify
```

## Per-host differences

Use templates: rename a file to `<name>.tmpl` and branch on
`{{ .chezmoi.hostname }}` / `{{ .chezmoi.os }}`. Host-wide ignores live
in `.chezmoiignore.tmpl` (KDE/GTK and the Handy kwtype setup are Linux-only).

`fish_variables`, `fish_env` and zsh are deliberately NOT managed:
universal variables and secrets are per-machine state. The login shell
is set to fish by `run_once_after_90-fish-default-shell.sh.tmpl`
(may ask for sudo on first apply).

The Ansible workstation playbook installs tooling before applying these files and
sets the fish login shell as root, avoiding an interactive `chsh` prompt during
automated apply. Standalone chezmoi initialization still uses the shell hook above.

## bat theme

The tracked `tokyonight_moon` theme is compiled into bat's machine-local cache by
`run_onchange_after_20-build-bat-cache.sh.tmpl` on first apply and when the tracked
bat config or theme changes. Install bat before applying. After a bat upgrade or
cache deletion, rebuild manually with `bat cache --build`; do not track the cache.

## Handy

The settings file and autostart entry are Linux-only: the tracked typing backend
is `kwtype`, provided alongside Handy by the Ansible workstation package groups.
Download the selected speech model separately on each machine.

The settings store is managed as a whole file, including empty provider API-key
fields. Applying it replaces local values in those fields; keep this baseline
credential-free and review it before `chezmoi re-add`. Do not add model files,
recordings, or provider credentials to Git.

## oh-my-pi

Manage `~/.omp/agent/config.yml` (model roles, thinking level, theme, and
composer preferences) as `dot_omp/private_agent/private_config.yml.tmpl`.
Chezmoi restores the agent directory with mode `0700` and the config with
mode `0600`.

The file is a template because `modelRoles.default` is a per-machine choice:
it branches on `{{ .chezmoi.hostname }}` (desktop vs laptop) with a fallback
for unlisted hosts. Everything else is shared, so changing a model is a
one-line host branch rather than a capture that silently reverts the other
machine on its next apply.

Only this config file is tracked. Credentials, databases, sessions, caches,
logs, and device IDs remain machine-local; authenticate separately on each
machine. Do not add the whole `~/.omp` directory or put secrets in the
tracked config.

After changing settings in oh-my-pi, capture them with:

```sh
chezmoi add --secrets=error ~/.omp/agent/config.yml
```

Then fold the change back into the template, keeping the `modelRoles.default`
host branch instead of pinning one machine's value.

## SSH config

`~/.ssh/config` is tracked as `private_dot_ssh/private_config`: a `Host *`
defaults block (identity file, `IdentitiesOnly`, keepalive) plus fleet aliases
over the Tailscale MagicDNS domain.

Per-machine stanzas go in the untracked `~/.ssh/config.d/*.conf`, which the
tracked file includes FIRST — ssh uses the first obtained value, so local
stanzas win over the shared defaults and survive reapplication. That directory
is excluded from management for the same reason. Check the result without
connecting: `ssh -G <host>`.

Private keys, `known_hosts` and `authorized_keys` are NOT tracked. The
authorized key set is owned by the homelab repository (`files/ssh/` and
`workstation_ssh_keys`).

## Fonts

`~/.config/fontconfig/fonts.conf` is tracked: rendering policy only — artificial
oblique for faces without italics, synthetic bold for faces without a bold cut,
hinting/antialias. It pins no font families and no DPI, so it is identical on
every machine. Verify it is loaded with `fc-conflist` and its effect with
`fc-match -v <family>`.

Fontconfig ships no fonts: families come from the OS installation, and app-level
font choices stay with the app (ghostty's `font-family`, KDE's font settings).
The family ghostty names is installed by the Ansible workstation package
declaration (`ttf-firacode-nerd`), so the terminal is the one place a font family
is pinned — in the app config, not in fontconfig.
Per-display DPI belongs in the user `fontconfig/conf.d/` directory, which is not
tracked.

## KDE Plasma settings

Managed as individual rc-files (kdeglobals, kglobalshortcutsrc, kxkbrc,
kwinrulesrc, ...), not one big config. Hardware/session state is deliberately NOT
managed: kwinoutputconfig.json (monitor layout), plasma appletsrc,
powermanagementprofilesrc, kwalletrc, kded*, session/.

Plasma rewrites these files at runtime and on logout, so:

- change settings in the GUI, then capture: `chezmoi re-add`
- apply them while the Plasma session is NOT running: log out first, then apply
  (`chezmoi update` / `chezmoi apply --force`) over SSH or from a console, then
  log in. Applying with a session running is silently reverted on exit: that
  session writes its stale in-memory values over the file (observed on starling
  — the Keyboard Layout Switcher's `Switch to Next Keyboard Layout` and KWin's
  `Walk Through Windows` went back to their KDE defaults, and a layout list of
  `us,ru` never reached the running session)
- verify the running state, not just the file:
  `gdbus call --session --dest org.kde.keyboard --object-path /Layouts --method org.kde.KeyboardLayouts.getLayoutsList`
  must list every layout from `kxkbrc` (e.g. `us` and `ru`), and
  `diff ~/.config/kglobalshortcutsrc "$(chezmoi source-path)/dot_config/private_kglobalshortcutsrc"`
  must be empty after the session has restarted
