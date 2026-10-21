#!/usr/bin/env bash
set -e

# mc-rclone installer
# Installs rclone+ extfs helper to ~/.local/share/mc/extfs.d/

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/share/mc/extfs.d"
TARGET_FILE="${TARGET_DIR}/rclone+"

echo "==> Installing mc-rclone..."

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

# Install mc-rclone utility to ~/.local/bin/mc-rclone (does not touch system mc)
mkdir -p "${HOME}/.local/bin"
chmod +x "${SCRIPT_DIR}/mc-rclone"
ln -sf "${SCRIPT_DIR}/mc-rclone" "${HOME}/.local/bin/mc-rclone"

# Sync hotlist bookmarks
"${SCRIPT_DIR}/mc-rclone" sync

echo "==> Successfully installed:"
echo "    - Rclone manager: ${HOME}/.local/bin/mc-rclone"
echo "    - ExtFS helper:   ${TARGET_FILE}"
echo ""
echo "How to use:"
echo "  - In Midnight Commander (mc):"
echo "    Press Ctrl+\\ (Directory Hotlist) to connect to any cloud remote."
echo "  - To start/stop background servers:"
echo "    mc-rclone start    # starts local listeners"
echo "    mc-rclone stop     # stops all servers"
echo "    mc-rclone status   # shows running status"


