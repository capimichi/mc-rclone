#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_SCRIPTS_DIR="${HOME}/.local/share/mc/scripts"
TARGET_EXTFS_DIR="${HOME}/.local/share/mc/extfs.d"
BRIDGE_LINK="${TARGET_SCRIPTS_DIR}/mc-rclone-bridge"
EXTFS_LINK="${TARGET_EXTFS_DIR}/rclone+"
MENU_FILE="${HOME}/.config/mc/menu"
HOTLIST_FILE="${HOME}/.config/mc/hotlist"

echo "==> Installing mc-rclone for GNU Midnight Commander..."

# 1. Check prerequisites
if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is required but not installed." >&2
    exit 1
fi
if ! command -v rclone &>/dev/null; then
    echo "Warning: 'rclone' executable not found in PATH. Make sure rclone is installed." >&2
fi

# 2. Install bridge script
mkdir -p "${TARGET_SCRIPTS_DIR}"
chmod +x "${SCRIPT_DIR}/mc-rclone-bridge"
ln -sf "${SCRIPT_DIR}/mc-rclone-bridge" "${BRIDGE_LINK}"
echo "✓ Installed bridge to ${BRIDGE_LINK}"

# 3. Also install ExtFS helper for backward compatibility
mkdir -p "${TARGET_EXTFS_DIR}"
if [ -f "${SCRIPT_DIR}/rclone+" ]; then
    chmod +x "${SCRIPT_DIR}/rclone+"
    ln -sf "${SCRIPT_DIR}/rclone+" "${EXTFS_LINK}"
    echo "✓ Installed ExtFS helper to ${EXTFS_LINK}"
fi

# 4. Configure User Menu (~/.config/mc/menu)
mkdir -p "$(dirname "${MENU_FILE}")"
touch "${MENU_FILE}"

python3 - <<EOF
import os

menu_path = os.path.expanduser("${MENU_FILE}")
content = ""
if os.path.isfile(menu_path):
    with open(menu_path, "r") as f:
        content = f.read()

# Remove existing block if present
lines = content.splitlines(keepends=True)
filtered = []
skip = False
for line in lines:
    if "# START_MC_RCLONE" in line:
        skip = True
        continue
    if "# END_MC_RCLONE" in line:
        skip = False
        continue
    if "rclone://" in line or (line.strip().startswith("R") and "Connect to Rclone" in line):
        continue
    if not skip:
        filtered.append(line)

new_content = "".join(filtered).rstrip()
block = """
# START_MC_RCLONE
R       Cloud Storage (Rclone All Remotes)
	${HOME}/.local/share/mc/scripts/mc-rclone-bridge start \$PPID
	%cd /#ftp:127.0.0.1:2123/
# END_MC_RCLONE
"""
final_content = (new_content + "\n" + block.lstrip()).lstrip()
with open(menu_path, "w") as f:
    f.write(final_content)
EOF
echo "✓ Configured User Menu entry in ${MENU_FILE} (F2 -> R)"

# 5. Configure Directory Hotlist (~/.config/mc/hotlist)
mkdir -p "$(dirname "${HOTLIST_FILE}")"
touch "${HOTLIST_FILE}"
if ! grep -q "127.0.0.1:2123" "${HOTLIST_FILE}" 2>/dev/null; then
    cat >> "${HOTLIST_FILE}" << 'EOF'
ENTRY "Cloud: Rclone (All Remotes)" URL "/#ftp:127.0.0.1:2123/"
EOF
    echo "✓ Added hotlist bookmark 'Cloud: Rclone (All Remotes)'"
fi

echo ""
echo "==> Installation complete!"
echo "How to use:"
echo "  1. Launch Midnight Commander: mc"
echo "  2. Press F2 (User Menu) and select 'R' (Cloud Storage)"
echo "     -> Automatically starts on-demand FTP server bound to MC and opens remotes!"
echo "  3. Deep navigation across subfolders is instant and on-demand."
