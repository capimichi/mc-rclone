#!/usr/bin/env bash
set -e

# mc-rclone installer
# Installs rclone+ extfs helper to ~/.local/share/mc/extfs.d/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/share/mc/extfs.d"
TARGET_FILE="${TARGET_DIR}/rclone+"
HOTLIST_FILE="${HOME}/.config/mc/hotlist"

echo "==> Installing mc-rclone plugin for Midnight Commander..."

# Ensure target directory exists
mkdir -p "${TARGET_DIR}"

# Check Python 3
if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is required but not installed." >&2
    exit 1
fi

# Check rclone
if ! command -v rclone &>/dev/null; then
    echo "Warning: 'rclone' executable not found in PATH. Make sure rclone is installed." >&2
fi

# Copy or symlink helper
chmod +x "${SCRIPT_DIR}/rclone+"
ln -sf "${SCRIPT_DIR}/rclone+" "${TARGET_FILE}"

# Add Hotlist entry if not already present
if [ -f "${HOTLIST_FILE}" ]; then
    if ! grep -q "/#rclone+" "${HOTLIST_FILE}"; then
        echo 'ENTRY "Cloud: Rclone (All Remotes)" URL "/#rclone+"' >> "${HOTLIST_FILE}"
        echo "==> Added Rclone bookmark to Midnight Commander Hotlist."
    fi
else
    mkdir -p "$(dirname "${HOTLIST_FILE}")"
    echo 'ENTRY "Cloud: Rclone (All Remotes)" URL "/#rclone+"' > "${HOTLIST_FILE}"
    echo "==> Created Midnight Commander Hotlist with Rclone bookmark."
fi

echo "==> Successfully installed mc-rclone plugin:"
echo "    ${TARGET_FILE}"
echo ""
echo "How to use:"
echo "  1. Open Midnight Commander: mc"
echo "  2. Press Ctrl+\\ (Directory Hotlist) and select 'Cloud: Rclone'"
echo "     or simply navigate to: cd /#rclone+"
echo ""
echo "100% portable: No background daemons, no services, no open ports."
