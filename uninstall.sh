#!/usr/bin/env bash
# Remove the scripts installed by install.sh.
#
# Only symlinks that point into this repository are removed. Real files that
# were copied (--copy) or created by you are left untouched.
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.config/bin"
RESET_KEYS=0

usage() {
    cat <<'EOF'
Usage: ./uninstall.sh [--reset-keys]

  --reset-keys  Also reset the button 1 quick-toggle keys.
  -h, --help    Show this help.
EOF
}

for arg in "$@"; do
    case "$arg" in
        --reset-keys) RESET_KEYS=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $arg" >&2; usage >&2; exit 2 ;;
    esac
done

for src in "$REPO_DIR"/bin/*; do
    name="$(basename "$src")"
    target="$BIN_DIR/$name"
    if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$src")" ]; then
        rm -f "$target"
        echo "removed $target"
    elif [ -e "$target" ]; then
        echo "keeping $target (not a symlink into this repository)"
    fi
done

if [ "$RESET_KEYS" -eq 1 ]; then
    base="/org/gnome/shell/extensions/custom-command-toggle"
    for key in buttonclick1-setting entryrow1-setting entryrow2-setting \
               entryrow3-setting entryrow4-setting showindicator1-setting; do
        dconf reset "$base/$key" || true
        echo "reset $base/$key"
    done
fi

cat <<'EOF'

Note: the WhiteSur themes, icons and extensions were not installed by this
repository, so they are left as they are.
EOF
