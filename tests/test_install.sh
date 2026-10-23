#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TEST_SANDBOX="$(mktemp -d)"
trap 'rm -rf "${TEST_SANDBOX}"' EXIT

export MC_RCLONE_HOME="${TEST_SANDBOX}"
export HOME="${TEST_SANDBOX}"

# Mock rclone config in sandbox
mkdir -p "$TEST_SANDBOX/.config/rclone"
cat <<'EOF' > "$TEST_SANDBOX/.config/rclone/rclone.conf"
[testremote]
type = alias
remote = /tmp
EOF

# 1. Run install
"$REPO_DIR/install.sh"

# 2. Verify files are copied and executable (not symlinks)
test -f "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
test ! -L "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
test -x "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
test -f "$TEST_SANDBOX/.local/bin/mc-rclone"
test ! -L "$TEST_SANDBOX/.local/bin/mc-rclone"
test -x "$TEST_SANDBOX/.local/bin/mc-rclone"
test -f "$TEST_SANDBOX/.config/mc-rclone/config.ini"

# 3. Verify menu contains shortcuts
grep -q "mc-rclone select" "$TEST_SANDBOX/.config/mc/menu"
grep -q "mc-rclone stop" "$TEST_SANDBOX/.config/mc/menu"
grep -q "mc-rclone status" "$TEST_SANDBOX/.config/mc/menu"

# 4. Verify dynamic hotlist behavior
"$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone" select testremote
grep -q 'ENTRY "Cloud: testremote" URL "ftp://127.0.0.1:2123"' "$TEST_SANDBOX/.config/mc/hotlist"

# Stop server and verify hotlist cleaned
"$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone" stop
! grep -q 'Cloud: testremote' "$TEST_SANDBOX/.config/mc/hotlist"

echo "✓ Sandbox install and dynamic hotlist verification passed."

# 5. Run uninstall
"$REPO_DIR/uninstall.sh"

# 6. Verify symlink and configs cleaned
test ! -e "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
! grep -q "mc-rclone" "$TEST_SANDBOX/.config/mc/menu"
! grep -q "127.0.0.1:2123" "$TEST_SANDBOX/.config/mc/hotlist"

echo "✓ Sandbox uninstall verification passed."

# 7. Test with explicit custom XDG variables
CUSTOM_CONFIG="$TEST_SANDBOX/custom_xdg_config"
CUSTOM_DATA="$TEST_SANDBOX/custom_xdg_data"
CUSTOM_CACHE="$TEST_SANDBOX/custom_xdg_cache"

mkdir -p "$CUSTOM_CONFIG/rclone"
cat <<'EOF' > "$CUSTOM_CONFIG/rclone/rclone.conf"
[testremote]
type = alias
remote = /tmp
EOF

export XDG_CONFIG_HOME="$CUSTOM_CONFIG"
export XDG_DATA_HOME="$CUSTOM_DATA"
export XDG_CACHE_HOME="$CUSTOM_CACHE"

"$REPO_DIR/install.sh"

test -f "$CUSTOM_DATA/mc/scripts/mc-rclone"
test ! -L "$CUSTOM_DATA/mc/scripts/mc-rclone"
test -x "$CUSTOM_DATA/mc/scripts/mc-rclone"
test -f "$CUSTOM_CONFIG/mc-rclone/config.ini"
grep -q "mc-rclone select" "$CUSTOM_CONFIG/mc/menu"

"$CUSTOM_DATA/mc/scripts/mc-rclone" select testremote
grep -q 'ENTRY "Cloud: testremote" URL "ftp://127.0.0.1:2123"' "$CUSTOM_CONFIG/mc/hotlist"

"$CUSTOM_DATA/mc/scripts/mc-rclone" stop
! grep -q 'Cloud: testremote' "$CUSTOM_CONFIG/mc/hotlist"

echo "✓ Sandbox custom XDG paths install and dynamic hotlist verification passed."

"$REPO_DIR/uninstall.sh"

test ! -e "$CUSTOM_DATA/mc/scripts/mc-rclone"
! grep -q "mc-rclone" "$CUSTOM_CONFIG/mc/menu"

echo "✓ Sandbox custom XDG paths uninstall verification passed."
