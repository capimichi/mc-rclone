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

echo "==> Successfully installed to: ${TARGET_FILE}"
echo ""
echo "How to use in Midnight Commander:"
echo "  1. Open Midnight Commander: mc"
echo "  2. Press Alt+C (Quick cd)"
echo "  3. Type: rclone:// and press Enter"
echo "  4. Browse and manage your cloud files transparently!"
