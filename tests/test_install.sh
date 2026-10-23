#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TEST_SANDBOX="$(mktemp -d)"
trap 'rm -rf "${TEST_SANDBOX}"' EXIT

export MC_RCLONE_HOME="${TEST_SANDBOX}"
export HOME="${TEST_SANDBOX}"

# 1. Run install with default paths
"$REPO_DIR/install.sh"

# 2. Verify files and links in default paths
test -L "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
test -x "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
test -f "$TEST_SANDBOX/.config/mc-rclone/config.ini"

# 3. Verify menu contains shortcuts
grep -q "mc-rclone start" "$TEST_SANDBOX/.config/mc/menu"
grep -q "mc-rclone stop" "$TEST_SANDBOX/.config/mc/menu"
grep -q "mc-rclone status" "$TEST_SANDBOX/.config/mc/menu"

# 4. Verify hotlist contains entry
grep -q "ftp://127.0.0.1:2123" "$TEST_SANDBOX/.config/mc/hotlist"

echo "✓ Sandbox default install verification passed."

# 5. Run uninstall
"$REPO_DIR/uninstall.sh"

# 6. Verify symlink and configs cleaned
test ! -e "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
! grep -q "mc-rclone" "$TEST_SANDBOX/.config/mc/menu"
! grep -q "127.0.0.1:2123" "$TEST_SANDBOX/.config/mc/hotlist"

echo "✓ Sandbox default uninstall verification passed."

# 7. Test with explicit custom XDG variables
CUSTOM_CONFIG="$TEST_SANDBOX/custom_xdg_config"
CUSTOM_DATA="$TEST_SANDBOX/custom_xdg_data"
CUSTOM_CACHE="$TEST_SANDBOX/custom_xdg_cache"

export XDG_CONFIG_HOME="$CUSTOM_CONFIG"
export XDG_DATA_HOME="$CUSTOM_DATA"
export XDG_CACHE_HOME="$CUSTOM_CACHE"

"$REPO_DIR/install.sh"

test -L "$CUSTOM_DATA/mc/scripts/mc-rclone"
test -x "$CUSTOM_DATA/mc/scripts/mc-rclone"
test -f "$CUSTOM_CONFIG/mc-rclone/config.ini"
grep -q "mc-rclone start" "$CUSTOM_CONFIG/mc/menu"
grep -q "ftp://127.0.0.1:2123" "$CUSTOM_CONFIG/mc/hotlist"

echo "✓ Sandbox custom XDG paths install verification passed."

"$REPO_DIR/uninstall.sh"

test ! -e "$CUSTOM_DATA/mc/scripts/mc-rclone"
! grep -q "mc-rclone" "$CUSTOM_CONFIG/mc/menu"
! grep -q "127.0.0.1:2123" "$CUSTOM_CONFIG/mc/hotlist"

echo "✓ Sandbox custom XDG paths uninstall verification passed."
