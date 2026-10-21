#!/usr/bin/env bash
set -e

# mc-rclone uninstaller

TARGET_FILE="${HOME}/.local/share/mc/extfs.d/rclone+"
CACHE_DIR="${HOME}/.cache/mc/rclone"

echo "==> Uninstalling mc-rclone..."

if [ -L "${TARGET_FILE}" ] || [ -f "${TARGET_FILE}" ]; then
    rm -f "${TARGET_FILE}"
    echo "Removed: ${TARGET_FILE}"
else
    echo "File not found: ${TARGET_FILE}"
fi

if [ -d "${CACHE_DIR}" ]; then
    rm -rf "${CACHE_DIR}"
    echo "Removed cache: ${CACHE_DIR}"
fi

echo "==> mc-rclone uninstalled."
