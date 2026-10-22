#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TEST_SANDBOX="$(mktemp -d)"
trap 'rm -rf "${TEST_SANDBOX}"' EXIT

export MC_RCLONE_HOME="${TEST_SANDBOX}"
export HOME="${TEST_SANDBOX}"

# 1. Run install
"$REPO_DIR/install.sh"

# 2. Verify files and links
test -L "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
test -x "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
test -f "$TEST_SANDBOX/.config/mc-rclone/config.ini"

# 3. Verify menu contains shortcuts
grep -q "mc-rclone start" "$TEST_SANDBOX/.config/mc/menu"
grep -q "mc-rclone stop" "$TEST_SANDBOX/.config/mc/menu"
grep -q "mc-rclone status" "$TEST_SANDBOX/.config/mc/menu"

# 4. Verify hotlist contains entry
grep -q "ftp://127.0.0.1:2123" "$TEST_SANDBOX/.config/mc/hotlist"

echo "✓ Sandbox install verification passed."

# 5. Run uninstall
"$REPO_DIR/uninstall.sh"

# 6. Verify symlink and configs cleaned
test ! -e "$TEST_SANDBOX/.local/share/mc/scripts/mc-rclone"
! grep -q "mc-rclone" "$TEST_SANDBOX/.config/mc/menu"
! grep -q "127.0.0.1:2123" "$TEST_SANDBOX/.config/mc/hotlist"

echo "✓ Sandbox uninstall verification passed."
