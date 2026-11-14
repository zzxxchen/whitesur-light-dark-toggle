#!/usr/bin/env bash
# Install whitesur-light-dark-toggle into ~/.config/bin and configure the
# Custom Command Toggle quick settings button (button 1 only).
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.config/bin"
MODE="link"
DRY_RUN=0
BACKUP_SUFFIX="$(date +%Y%m%d-%H%M%S)"

usage() {
    cat <<'EOF'
Usage: ./install.sh [--copy] [--dry-run]

  --copy      Copy the scripts instead of symlinking them.
  --dry-run   Print what would be done, change nothing.
  -h, --help  Show this help.

By default the scripts are symlinked into ~/.config/bin, so a later
`git pull` updates them in place.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --copy) MODE="copy" ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

warn() {
    printf '  ! %s\n' "$*" >&2
}

echo "==> Checking dependencies"
for cmd in dconf gsettings; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Missing required command: $cmd" >&2
        exit 1
    fi
done
if ! python3 -c 'import gi' >/dev/null 2>&1; then
    warn "python3-gi is missing; rounded-corners-borders and vscode-theme will not work."
    warn "On Debian/Ubuntu: sudo apt install python3-gi"
fi

echo "==> Installing scripts into ${BIN_DIR}"
run mkdir -p "$BIN_DIR"
for src in "$REPO_DIR"/bin/*; do
    name="$(basename "$src")"
    target="$BIN_DIR/$name"

    if [ -L "$target" ] || [ -e "$target" ]; then
        if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
            : # already points at this repository
        else
            backup="$target.bak-$BACKUP_SUFFIX"
            echo "    backing up $name -> $backup"
            run mv "$target" "$backup"
        fi
    fi

    if [ "$MODE" = "copy" ]; then
        run cp "$src" "$target"
    else
        run ln -sfn "$(readlink -f "$src")" "$target"
    fi
    run chmod +x "$target"
done

echo "==> Configuring the quick settings toggle (button 1 only)"
toggle_key() {
    local key="$1"
    local value="$2"
    run dconf write "/org/gnome/shell/extensions/custom-command-toggle/${key}" "$value"
}
toggle_key buttonclick1-setting "2"
toggle_key entryrow1-setting "'sh ${BIN_DIR}/theme-dark.sh'"
toggle_key entryrow2-setting "'sh ${BIN_DIR}/theme-light.sh'"
toggle_key entryrow3-setting "'WhiteSur Dark'"
toggle_key entryrow4-setting "'dark-mode-symbolic'"
toggle_key showindicator1-setting "false"

echo "==> Checking themes and extensions"
for dir in \
    "$HOME/.themes/WhiteSur-Dark-blue" \
    "$HOME/.themes/WhiteSur-Light-blue"; do
    [ -d "$dir" ] || warn "missing GTK theme: $dir"
done
if [ ! -d "$HOME/.local/share/icons/WhiteSur" ] && [ ! -d "/usr/share/icons/WhiteSur" ]; then
    warn "missing icon theme: WhiteSur"
fi
if [ ! -f "$HOME/.config/gtk-4.0/gtk-Light.css" ] || [ ! -f "$HOME/.config/gtk-4.0/gtk-Dark.css" ]; then
    warn "WhiteSur GTK4 CSS not found in ~/.config/gtk-4.0; gtk4-merge-css will be a no-op."
fi

ENABLED_EXTENSIONS="$(gnome-extensions list --enabled 2>/dev/null || true)"
is_enabled() {
    case "$ENABLED_EXTENSIONS" in
        *"$1"*) return 0 ;;
        *) return 1 ;;
    esac
}
for ext in \
    user-theme@gnome-shell-extensions.gcampax.github.com \
    custom-command-toggle@storageb.github.com; do
    is_enabled "$ext" || warn "extension is not enabled: $ext"
done
is_enabled rounded-window-corners@fxgn ||
    warn "rounded-window-corners@fxgn is not enabled; border colour switching will be skipped."

cat <<EOF

Done.

Remaining manual steps:
  1. Install the WhiteSur GTK/shell theme and icon theme if you have not yet:
       https://github.com/vinceliuice/WhiteSur-gtk-theme    (blue variants)
       https://github.com/vinceliuice/WhiteSur-icon-theme
     The scripts expect ~/.themes/WhiteSur-{Light,Dark}-blue and the
     WhiteSur icon theme.
  2. Install and enable the extensions user-theme, custom-command-toggle and
     (optionally) rounded-window-corners.
  3. Open Quick Settings and click the "WhiteSur Dark" toggle to test.
  4. If you installed with --copy, re-run ./install.sh after updating the repo.

If the top bar only changes after a delay, read docs/troubleshooting.md.
EOF
