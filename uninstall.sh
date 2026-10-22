#!/usr/bin/env bash
set -euo pipefail

TARGET_SCRIPTS_DIR="${HOME}/.local/share/mc/scripts"
TARGET_EXTFS_DIR="${HOME}/.local/share/mc/extfs.d"
BRIDGE_LINK="${TARGET_SCRIPTS_DIR}/mc-rclone-bridge"
EXTFS_LINK="${TARGET_EXTFS_DIR}/rclone+"
CACHE_DIR="${HOME}/.cache/mc/rclone"
MENU_FILE="${HOME}/.config/mc/menu"
HOTLIST_FILE="${HOME}/.config/mc/hotlist"

echo "==> Uninstalling mc-rclone..."

# 1. Stop bridge if running
if [ -x "${BRIDGE_LINK}" ]; then
    "${BRIDGE_LINK}" stop || true
fi

# 2. Remove script links
if [ -L "${BRIDGE_LINK}" ] || [ -f "${BRIDGE_LINK}" ]; then
    rm -f "${BRIDGE_LINK}"
    echo "✓ Removed ${BRIDGE_LINK}"
fi
if [ -L "${EXTFS_LINK}" ] || [ -f "${EXTFS_LINK}" ]; then
    rm -f "${EXTFS_LINK}"
    echo "✓ Removed ${EXTFS_LINK}"
fi

# 3. Clean user menu
if [ -f "${MENU_FILE}" ]; then
    python3 - <<EOF
import os
menu_path = os.path.expanduser("${MENU_FILE}")
if os.path.isfile(menu_path):
    with open(menu_path, "r") as f:
        lines = f.readlines()
    filtered = []
    skip = False
    for line in lines:
        if "# START_MC_RCLONE" in line or "mc-rclone-bridge" in line:
            skip = True
            continue
        if "# END_MC_RCLONE" in line:
            skip = False
            continue
        if not skip:
            filtered.append(line)
    with open(menu_path, "w") as f:
        f.writelines(filtered)
EOF
    echo "✓ Cleaned user menu entries in ${MENU_FILE}"
fi

# 4. Clean hotlist
if [ -f "${HOTLIST_FILE}" ]; then
    python3 - <<EOF
import os
hl_path = os.path.expanduser("${HOTLIST_FILE}")
if os.path.isfile(hl_path):
    with open(hl_path, "r") as f:
        lines = f.readlines()
    filtered = [l for l in lines if "127.0.0.1:2123" not in l and "rclone+" not in l]
    with open(hl_path, "w") as f:
        f.writelines(filtered)
EOF
    echo "✓ Cleaned hotlist entries in ${HOTLIST_FILE}"
fi

# 5. Clean cache
if [ -d "${CACHE_DIR}" ]; then
    rm -rf "${CACHE_DIR}"
    echo "✓ Removed cache ${CACHE_DIR}"
fi

echo "==> mc-rclone uninstalled successfully."
