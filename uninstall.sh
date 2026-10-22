#!/usr/bin/env bash
set -e

# mc-rclone uninstaller

TARGET_FILE="${HOME}/.local/share/mc/extfs.d/rclone+"
BIN_FILE="${HOME}/.local/bin/mc-rclone"
CACHE_DIR="${HOME}/.cache/mc/rclone"

echo "==> Uninstalling mc-rclone..."

# Disable launchd service if installed
if command -v "${BIN_FILE}" &>/dev/null; then
    "${BIN_FILE}" service-uninstall 2>/dev/null || true
    "${BIN_FILE}" stop 2>/dev/null || true
fi

if [ -L "${BIN_FILE}" ] || [ -f "${BIN_FILE}" ]; then
    rm -f "${BIN_FILE}"
    echo "Removed: ${BIN_FILE}"
fi

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
