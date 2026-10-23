#!/usr/bin/env bash
set -euo pipefail

if [ -n "${MC_RCLONE_HOME:-}" ]; then
    TARGET_HOME="${MC_RCLONE_HOME}"
elif [[ "${HOME}" == *"multiagy"* ]] && [ -d "/Users/michele" ]; then
    TARGET_HOME="/Users/michele"
else
    TARGET_HOME="${HOME}"
fi

TARGET_CONFIG_HOME="${XDG_CONFIG_HOME:-${TARGET_HOME}/.config}"
TARGET_DATA_HOME="${XDG_DATA_HOME:-${TARGET_HOME}/.local/share}"
TARGET_CACHE_HOME="${XDG_CACHE_HOME:-${TARGET_HOME}/.cache}"

TARGET_SCRIPTS_DIR="${TARGET_DATA_HOME}/mc/scripts"
TARGET_BIN_DIR="${TARGET_HOME}/.local/bin"
SCRIPT_LINK="${TARGET_SCRIPTS_DIR}/mc-rclone"
OLD_BRIDGE_LINK="${TARGET_SCRIPTS_DIR}/mc-rclone-bridge"
BIN_LINK="${TARGET_BIN_DIR}/mc-rclone"
TARGET_EXTFS_DIR="${TARGET_DATA_HOME}/mc/extfs.d"
OLD_EXTFS_LINK="${TARGET_EXTFS_DIR}/rclone+"
CACHE_DIR="${TARGET_CACHE_HOME}/mc/rclone"
MENU_FILE="${TARGET_CONFIG_HOME}/mc/menu"
HOTLIST_FILE="${TARGET_CONFIG_HOME}/mc/hotlist"

echo "==> Uninstalling mc-rclone..."

# 1. Stop server if running
if [ -x "${SCRIPT_LINK}" ]; then
    "${SCRIPT_LINK}" stop || true
elif [ -x "${OLD_BRIDGE_LINK}" ]; then
    "${OLD_BRIDGE_LINK}" stop || true
fi

# 2. Remove script links
for link in "${SCRIPT_LINK}" "${OLD_BRIDGE_LINK}" "${BIN_LINK}" "${OLD_EXTFS_LINK}"; do
    if [ -L "${link}" ] || [ -f "${link}" ]; then
        rm -f "${link}"
        echo "✓ Removed ${link}"
    fi
done

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
        if "# START_MC_RCLONE" in line:
            skip = True
            continue
        if "# END_MC_RCLONE" in line:
            skip = False
            continue
        if "mc-rclone" in line or "mc-rclone-bridge" in line:
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
    filtered = [l for l in lines if "127.0.0.1:" not in l and "rclone+" not in l]
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
