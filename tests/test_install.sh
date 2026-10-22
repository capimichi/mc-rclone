#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Run install
"$REPO_DIR/install.sh"

# Verify symlink exists
test -L "$HOME/.local/share/mc/scripts/mc-rclone-bridge"
test -x "$HOME/.local/share/mc/scripts/mc-rclone-bridge"

# Verify menu contains shortcut
grep -q "mc-rclone-bridge start" "$HOME/.config/mc/menu"

# Verify hotlist contains entry
grep -q "ftp://127.0.0.1:2123" "$HOME/.config/mc/hotlist"

echo "Install verification passed."

# Run uninstall
"$REPO_DIR/uninstall.sh"

# Verify symlink removed
test ! -e "$HOME/.local/share/mc/scripts/mc-rclone-bridge"

# Verify menu cleaned
! grep -q "mc-rclone-bridge" "$HOME/.config/mc/menu"

echo "Uninstall verification passed."
