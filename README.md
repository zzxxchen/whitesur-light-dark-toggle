# WhiteSur Light/Dark Toggle

[English](README.md) | [简体中文](README.zh-CN.md)

A GNOME Shell Quick Settings toggle that switches between the WhiteSur light and dark themes with a single click.

The scripts switch the shell theme, GTK theme, icon theme, window decorations, the system color-scheme preference, rounded window corner border colors, and the VS Code color theme. The shell theme is applied first, so the top bar visibly changes almost instantly.

Tested on GNOME Shell 50.1 (Ubuntu).

## Layout

```
whitesur-light-dark-toggle/
├── bin/
│   ├── theme-dark.sh            # switch to dark
│   ├── theme-light.sh           # switch to light
│   ├── gtk4-merge-css           # build a light/dark merged GTK4 gtk.css
│   ├── rounded-corners-borders  # sync rounded-window-corners border colors
│   └── vscode-theme             # sync the VS Code colorTheme
├── config/
│   └── custom-command-toggle.dconf     # reference config for the quick toggle
├── extras/
│   └── rounded-corners-personal.dconf  # personal per-app settings (not installed)
├── docs/
│   └── troubleshooting.md       # notes on toggle latency (Chinese)
├── install.sh
├── uninstall.sh
└── LICENSE
```

## Requirements

Required:

- GNOME Shell 45+ (tested on 50.1)
- [WhiteSur GTK theme](https://github.com/vinceliuice/WhiteSur-gtk-theme), blue variants:
  `~/.themes/WhiteSur-Light-blue` and `~/.themes/WhiteSur-Dark-blue`
- [WhiteSur icon theme](https://github.com/vinceliuice/WhiteSur-icon-theme): `WhiteSur`
- GNOME extension [user-theme](https://gitlab.gnome.org/GNOME/gnome-shell-extensions)
  (used to switch the shell theme)
- GNOME extension [Custom Command Toggle](https://github.com/StorageB/custom-command-toggle)
  (provides the Quick Settings button)

Optional:

- GNOME extension [rounded-window-corners-reborn](https://github.com/flexagoon/rounded-window-corners)
  (without it `rounded-corners-borders` exits with an error; everything else still works)
- VS Code / VSCodium (`vscode-theme` detects the common settings paths automatically)
- `python3-gi` (needed by `rounded-corners-borders` and `vscode-theme`)

## Installation

```bash
git clone https://github.com/zzxxchen/whitesur-light-dark-toggle.git
cd whitesur-light-dark-toggle
./install.sh
```

The installer:

1. Symlinks the scripts from `bin/` into `~/.config/bin/`
   (existing files are backed up as `*.bak-<timestamp>` first).
2. Configures button 1 of the quick toggle only (label, icon, dark/light commands);
   other buttons are left untouched.
3. Checks that the themes, icons and extensions are present and warns about anything missing.

Options:

```bash
./install.sh --dry-run   # print what would be done, change nothing
./install.sh --copy      # copy the scripts instead of symlinking them
```

Manual steps after installing:

1. Follow the official READMEs to install the WhiteSur GTK theme (blue, Light/Dark variants),
   the WhiteSur icon theme and the WhiteSur shell theme.
2. Enable the `user-theme`, `Custom Command Toggle` and (optionally)
   `rounded-window-corners` extensions.
3. Open Quick Settings and click the "WhiteSur Dark" toggle to test.

## How it works

`theme-dark.sh` / `theme-light.sh` run these steps in order:

1. `gtk4-merge-css` — makes sure `~/.config/gtk-4.0/gtk.css` is the merged light/dark
   stylesheet (two `@media (prefers-color-scheme: ...)` branches). Switching themes then
   never has to replace this file, and libadwaita apps follow `color-scheme` automatically.
2. `dconf write .../user-theme/name` — switches the shell theme. This is intentionally
   **first**: it is the most visible change, so the top bar, menus and overview update
   immediately while the heavier work triggered by `color-scheme` continues in the background.
3. `gsettings set ... color-scheme` — the system light/dark preference used by
   libadwaita and GTK4 applications.
4. Switch `gtk-theme`, `icon-theme` and `wm.preferences theme`.
5. `rounded-corners-borders light|dark` — only updates the border color; radius and other
   settings are preserved. Apps such as `Termius`, `steam` and `eudic` can keep a fixed
   color, see `PINNED_COLORS` in the script.
6. `vscode-theme light|dark` — replaces `workbench.colorTheme` only, leaving the rest of
   `settings.json` untouched.

## Customization

- Not using the blue variant: change `WhiteSur-Light-blue` / `WhiteSur-Dark-blue` in the
  two theme scripts.
- Different icon theme: change `icon-theme` in the scripts.
- Border colors: edit `DEFAULT_COLORS` and `PINNED_COLORS` at the top of
  `bin/rounded-corners-borders`.
- Pin more apps: add `app-id: color` entries to `PINNED_COLORS`.
- VS Code settings paths: edit `SETTINGS_CANDIDATES` in `bin/vscode-theme`.

## Toggle latency

If switching feels like it takes two or three seconds, see
[docs/troubleshooting.md](docs/troubleshooting.md) (Chinese). The main cause is
`blur-my-shell` rebuilding its blur effects synchronously on `color-scheme` changes, which
blocks the GNOME Shell main loop. The "shell theme first" ordering used by this repository
already brings the visible delay down to roughly 0.1 s.

## Uninstall

```bash
./uninstall.sh              # remove only the symlinks created by this repository
./uninstall.sh --reset-keys # also reset button 1 of the quick toggle
```

Themes, icons and extensions are not installed by this repository and are left untouched.

## License

[MIT](LICENSE)
