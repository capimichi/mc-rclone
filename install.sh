#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -n "${MC_RCLONE_HOME:-}" ]; then
    TARGET_HOME="${MC_RCLONE_HOME}"
elif [[ "${HOME}" == *"multiagy"* ]] && [ -d "/Users/michele" ]; then
    TARGET_HOME="/Users/michele"
else
    TARGET_HOME="${HOME}"
fi

TARGET_SCRIPTS_DIR="${TARGET_HOME}/.local/share/mc/scripts"
TARGET_BIN_DIR="${TARGET_HOME}/.local/bin"
SCRIPT_LINK="${TARGET_SCRIPTS_DIR}/mc-rclone"
BIN_LINK="${TARGET_BIN_DIR}/mc-rclone"
CONFIG_DIR="${TARGET_HOME}/.config/mc-rclone"
CONFIG_FILE="${CONFIG_DIR}/config.ini"
MENU_FILE="${TARGET_HOME}/.config/mc/menu"
HOTLIST_FILE="${TARGET_HOME}/.config/mc/hotlist"

echo "==> Installing mc-rclone for GNU Midnight Commander..."

# 1. Check prerequisites
if ! command -v python3 &>/dev/null; then
    echo "Error: python3 is required but not installed." >&2
    exit 1
fi
if ! command -v rclone &>/dev/null; then
    echo "Warning: 'rclone' executable not found in PATH. Make sure rclone is installed." >&2
fi

# 2. Install executable
mkdir -p "${TARGET_SCRIPTS_DIR}" "${TARGET_BIN_DIR}"
chmod +x "${SCRIPT_DIR}/mc-rclone"
ln -sf "${SCRIPT_DIR}/mc-rclone" "${SCRIPT_LINK}"
ln -sf "${SCRIPT_DIR}/mc-rclone" "${BIN_LINK}"
echo "✓ Installed mc-rclone to ${SCRIPT_LINK} and ${BIN_LINK}"

# 3. Initialize configuration file if missing
if [ ! -f "${CONFIG_FILE}" ]; then
    mkdir -p "${CONFIG_DIR}"
    "${SCRIPT_LINK}" status >/dev/null 2>&1 || true
    echo "✓ Initialized default configuration in ${CONFIG_FILE}"
else
    echo "✓ Existing configuration preserved in ${CONFIG_FILE}"
fi

# Determine configured port (default 2123)
PORT=$(python3 -c "
import configparser, os
cfg = os.path.expanduser('${CONFIG_FILE}')
p = 2123
if os.path.isfile(cfg):
    c = configparser.ConfigParser()
    c.read(cfg)
    p = c.getint('server', 'port', fallback=2123)
print(p)
")

# 4. Configure User Menu (~/.config/mc/menu)
mkdir -p "$(dirname "${MENU_FILE}")"
touch "${MENU_FILE}"

export PORT MENU_FILE SCRIPT_LINK HOTLIST_FILE
python3 - <<'EOF'
import os

menu_path = os.path.expanduser(os.environ.get("MENU_FILE", "~/.config/mc/menu"))
port = os.environ.get("PORT", "2123")
script_link = os.path.expanduser(os.environ.get("SCRIPT_LINK", "~/.local/share/mc/scripts/mc-rclone"))
content = ""
if os.path.isfile(menu_path):
    with open(menu_path, "r") as f:
        content = f.read()

# Remove existing mc-rclone blocks if present
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
    if "mc-rclone-bridge" in line or "rclone://" in line:
        continue
    if not skip:
        filtered.append(line)

new_content = "".join(filtered).rstrip()
block = f"""
# START_MC_RCLONE
R       Select / Mount Cloud Storage (Rclone)
	{script_link} select
	echo "Press Ctrl + \\\\ (Hotlist) -> 'Cloud: Rclone (All Remotes)' to browse."
	sleep 1

S       Stop Cloud Storage (Rclone Server)
	{script_link} stop
	sleep 1

?       Cloud Storage Status (Rclone Server)
	{script_link} status
	sleep 2
# END_MC_RCLONE
"""
final_content = (new_content + "\n" + block.lstrip()).lstrip()
with open(menu_path, "w") as f:
    f.write(final_content)
EOF
echo "✓ Configured User Menu entry in ${MENU_FILE} (F2 -> R / S / ?)"

# 5. Configure Directory Hotlist (~/.config/mc/hotlist)
mkdir -p "$(dirname "${HOTLIST_FILE}")"
touch "${HOTLIST_FILE}"
python3 - <<'EOF'
import os
hl_path = os.path.expanduser(os.environ.get("HOTLIST_FILE", "~/.config/mc/hotlist"))
port = os.environ.get("PORT", "2123")
lines = []
if os.path.isfile(hl_path):
    with open(hl_path, "r") as f:
        lines = f.readlines()
# Remove old /#rclone+ or duplicate entries
filtered = [l for l in lines if "/#rclone+" not in l and "127.0.0.1:" not in l]
filtered.append(f'ENTRY "Cloud: Rclone (All Remotes)" URL "ftp://127.0.0.1:{port}"\n')
with open(hl_path, "w") as f:
    f.writelines(filtered)
EOF
echo "✓ Configured Hotlist bookmark 'Cloud: Rclone (All Remotes)' (port ${PORT})"

echo ""
echo "==> Installation complete!"
echo "How to use:"
echo "  1. Launch Midnight Commander: mc"
echo "  2. Press F2 (User Menu) and select 'R' (Start Cloud Storage)"
echo "  3. Press Ctrl + \\ (Hotlist) and select 'Cloud: Rclone (All Remotes)'"
echo "  4. Deep navigation across subfolders is instant and on-demand."
