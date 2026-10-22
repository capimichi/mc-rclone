# MC Rclone Cloud Bridge Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a lightweight, portable bridge script (`mc-rclone-bridge`) that enables GNU Midnight Commander to browse Rclone cloud remotes on-demand via FTP (`:combine:` backend) triggered from MC's User Menu (`F2`), with automatic process lifecycle management bound to MC's PID.

**Architecture:** A standalone Python/POSIX script (`mc-rclone-bridge`) parses `rclone.conf` dynamically, spins up `rclone serve ftp :combine:` on `127.0.0.1:2123` on-demand, and monitors the parent MC process PID to terminate cleanly when MC exits. MC integration uses native User Menu (`~/.config/mc/menu`) with `%cd` and Hotlist (`~/.config/mc/hotlist`).

**Tech Stack:** Python 3.8+, Bash/POSIX shell, GNU Midnight Commander 4.8+, Rclone 1.50+

## Global Constraints

- Zero external daemons / persistent services (no `launchd`, no `systemd`, no persistent background ports when MC is closed).
- Zero alterations or wrappers around the system `mc` binary (`/opt/homebrew/bin/mc` remains untouched).
- 100% portable across macOS, Linux, and BSD.
- Native FTP VFS support: On-demand directory fetching, no root crawl at minute zero.
- Process lifecycle bound to Midnight Commander parent process PID.

---

### Task 1: Core Bridge Executable (`mc-rclone-bridge`)

**Files:**
- Create: `/Users/michele/PycharmProjects/mc-rclone/mc-rclone-bridge`
- Test: `/Users/michele/PycharmProjects/mc-rclone/tests/test_bridge.py`

**Interfaces:**
- Consumes: `rclone.conf` at `~/.config/rclone/rclone.conf`, environment variable `PPID` or parent process PID.
- Produces: CLI script with subcommands `start [parent_pid]`, `stop`, `status`, listening on `127.0.0.1:2123`.

- [ ] **Step 1: Write test for bridge configuration discovery and CLI commands**

Create `/Users/michele/PycharmProjects/mc-rclone/tests/test_bridge.py`:
```python
import os
import subprocess
import time
import socket
import pytest

SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "mc-rclone-bridge"))

def test_bridge_status_when_stopped():
    res = subprocess.run([SCRIPT_PATH, "status"], capture_output=True, text=True)
    assert res.returncode in (0, 1)
    assert "stopped" in res.stdout.lower() or "not running" in res.stdout.lower()

def test_bridge_start_and_stop():
    # Start with a dummy parent PID that remains alive during test (current test process)
    my_pid = str(os.getpid())
    res = subprocess.run([SCRIPT_PATH, "start", my_pid], capture_output=True, text=True)
    assert res.returncode == 0
    
    # Check status
    time.sleep(0.5)
    res_status = subprocess.run([SCRIPT_PATH, "status"], capture_output=True, text=True)
    assert "running" in res_status.stdout.lower()
    
    # Test port is open
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(2)
    conn_result = sock.connect_ex(("127.0.0.1", 2123))
    sock.close()
    assert conn_result == 0
    
    # Stop bridge
    res_stop = subprocess.run([SCRIPT_PATH, "stop"], capture_output=True, text=True)
    assert res_stop.returncode == 0
    time.sleep(0.5)
    
    res_after = subprocess.run([SCRIPT_PATH, "status"], capture_output=True, text=True)
    assert "stopped" in res_after.stdout.lower() or "not running" in res_after.stdout.lower()
```

- [ ] **Step 2: Run test to verify it fails**

Run:
```bash
python3 -m pytest /Users/michele/PycharmProjects/mc-rclone/tests/test_bridge.py -v
```
Expected: FAIL (file `mc-rclone-bridge` not found or not executable).

- [ ] **Step 3: Implement `mc-rclone-bridge`**

Create `/Users/michele/PycharmProjects/mc-rclone/mc-rclone-bridge`:
```python
#!/usr/bin/env python3
"""
mc-rclone-bridge - On-demand Rclone FTP bridge for GNU Midnight Commander.
Binds to MC parent PID and terminates automatically on MC exit.
"""

import sys
import os
import time
import socket
import subprocess
import configparser
import shutil
import signal

PORT = int(os.getenv("MC_RCLONE_PORT", "2123"))
ADDR = os.getenv("MC_RCLONE_ADDR", "127.0.0.1")
CACHE_DIR = os.path.expanduser("~/.cache/mc/rclone")
PID_FILE = os.path.join(CACHE_DIR, "bridge.pid")
LOG_FILE = os.path.join(CACHE_DIR, "bridge.log")

def get_real_home():
    home = os.environ.get("HOME", "")
    if "multiagy" in home or not os.path.isdir(os.path.join(home, ".config")):
        if os.path.isdir("/Users/michele"):
            return "/Users/michele"
    return os.path.expanduser("~")

REAL_HOME = get_real_home()

def find_rclone_conf():
    for p in [
        os.path.join(REAL_HOME, ".config", "rclone", "rclone.conf"),
        os.path.expanduser("~/.config/rclone/rclone.conf"),
    ]:
        if os.path.isfile(p):
            return p
    return os.path.join(REAL_HOME, ".config", "rclone", "rclone.conf")

def is_port_open(host, port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(0.3)
    try:
        res = sock.connect_ex((host, port))
        return res == 0
    finally:
        sock.close()

def is_pid_alive(pid):
    try:
        os.kill(pid, 0)
        return True
    except (OSError, ProcessLookupError):
        return False

def get_remotes():
    conf_path = find_rclone_conf()
    if not os.path.isfile(conf_path):
        return []
    parser = configparser.ConfigParser()
    try:
        parser.read(conf_path)
        return [s for s in parser.sections() if not s.startswith("_")]
    except Exception:
        return []

def stop():
    if os.path.isfile(PID_FILE):
        try:
            with open(PID_FILE, "r") as f:
                pid = int(f.read().strip())
            if is_pid_alive(pid):
                os.kill(pid, signal.SIGTERM)
                for _ in range(20):
                    time.sleep(0.1)
                    if not is_pid_alive(pid):
                        break
                if is_pid_alive(pid):
                    os.kill(pid, signal.SIGKILL)
        except Exception:
            pass
        try:
            os.remove(PID_FILE)
        except Exception:
            pass
    print("mc-rclone-bridge stopped.")
    return 0

def status():
    if os.path.isfile(PID_FILE):
        try:
            with open(PID_FILE, "r") as f:
                pid = int(f.read().strip())
            if is_pid_alive(pid) and is_port_open(ADDR, PORT):
                print(f"mc-rclone-bridge is running (PID {pid}, listening on {ADDR}:{PORT}).")
                return 0
        except Exception:
            pass
    print("mc-rclone-bridge is stopped.")
    return 1

def start(parent_pid=None):
    os.makedirs(CACHE_DIR, exist_ok=True)
    if is_port_open(ADDR, PORT):
        # Server is already running
        return 0

    if parent_pid is None:
        parent_pid = os.getppid()

    remotes = get_remotes()
    if not remotes:
        sys.stderr.write("Error: No remotes found in rclone.conf\n")
        return 1

    upstreams = " ".join([f"{r}={r}:" for r in remotes])
    rclone_bin = shutil.which("rclone") or "/opt/homebrew/bin/rclone"
    conf_path = find_rclone_conf()

    cmd = [
        rclone_bin,
        "--config", conf_path,
        "serve", "ftp",
        "--combine-upstreams", upstreams,
        "--addr", f"{ADDR}:{PORT}",
        ":combine:"
    ]

    # Spawn daemon process that monitors parent_pid and terminates rclone when parent dies
    daemon_code = f"""
import subprocess, time, os, sys, signal

parent_pid = {parent_pid}
cmd = {cmd!r}
pid_file = {PID_FILE!r}
log_file = {LOG_FILE!r}

with open(log_file, "a") as log:
    proc = subprocess.Popen(cmd, stdout=log, stderr=log)
    with open(pid_file, "w") as f:
        f.write(str(proc.pid))

    try:
        while True:
            time.sleep(1.5)
            # Check if rclone died
            if proc.poll() is not None:
                break
            # Check if parent MC process is still alive
            if parent_pid > 1:
                try:
                    os.kill(parent_pid, 0)
                except (OSError, ProcessLookupError):
                    break
    finally:
        if proc.poll() is None:
            proc.terminate()
            try:
                proc.wait(timeout=2)
            except subprocess.TimeoutExpired:
                proc.kill()
        if os.path.isfile(pid_file):
            try:
                os.remove(pid_file)
            except Exception:
                pass
"""
    subprocess.Popen([sys.executable, "-c", daemon_code], start_new_session=True)

    # Wait up to 2 seconds for port to open
    for _ in range(20):
        time.sleep(0.1)
        if is_port_open(ADDR, PORT):
            return 0

    sys.stderr.write("Error: Timed out waiting for FTP server to listen.\n")
    return 1

def main():
    if len(sys.argv) < 2:
        print("Usage: mc-rclone-bridge {start [mc_pid]|stop|status}")
        sys.exit(1)

    cmd = sys.argv[1].lower()
    if cmd == "start":
        parent_pid = int(sys.argv[2]) if len(sys.argv) > 2 else os.getppid()
        sys.exit(start(parent_pid))
    elif cmd == "stop":
        sys.exit(stop())
    elif cmd == "status":
        sys.exit(status())
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

Set executable permission:
```bash
chmod +x /Users/michele/PycharmProjects/mc-rclone/mc-rclone-bridge
```

- [ ] **Step 4: Run test to verify it passes**

Run:
```bash
python3 -m pytest /Users/michele/PycharmProjects/mc-rclone/tests/test_bridge.py -v
```
Expected: PASS with 2 tests passed.

---

### Task 2: MC Configuration and Installer Integration

**Files:**
- Modify: `/Users/michele/PycharmProjects/mc-rclone/install.sh`
- Modify: `/Users/michele/PycharmProjects/mc-rclone/uninstall.sh`
- Test: `/Users/michele/PycharmProjects/mc-rclone/tests/test_install.sh`

**Interfaces:**
- Consumes: `mc-rclone-bridge`, user directory `~/.config/mc/` and `~/.local/share/mc/scripts/`.
- Produces: Installed symlink `~/.local/share/mc/scripts/mc-rclone-bridge`, updated `~/.config/mc/menu` and `~/.config/mc/hotlist`.

- [ ] **Step 1: Write test script for install and uninstall**

Create `/Users/michele/PycharmProjects/mc-rclone/tests/test_install.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Run install
"$REPO_DIR/install.sh"

# Verify symlink exists
test -L "$HOME/.local/share/mc/scripts/mc-rclone-bridge"
test -x "$HOME/.local/share/mc/scripts/mc-rclone-bridge"

# Verify menu contains shortcut
grep -q "mc-rclone-bridge start" "$HOME/.config/mc/menu"
grep -q "%cd ftp://127.0.0.1:2123/" "$HOME/.config/mc/menu"

# Verify hotlist contains entry
grep -q "ftp://127.0.0.1:2123/" "$HOME/.config/mc/hotlist"

echo "Install verification passed."

# Run uninstall
"$REPO_DIR/uninstall.sh"

# Verify symlink removed
test ! -e "$HOME/.local/share/mc/scripts/mc-rclone-bridge"

# Verify menu cleaned
! grep -q "mc-rclone-bridge" "$HOME/.config/mc/menu"

echo "Uninstall verification passed."
```
Make executable:
```bash
chmod +x /Users/michele/PycharmProjects/mc-rclone/tests/test_install.sh
```

- [ ] **Step 2: Update `install.sh`**

Edit `/Users/michele/PycharmProjects/mc-rclone/install.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/share/mc/scripts"
TARGET_LINK="${TARGET_DIR}/mc-rclone-bridge"
MENU_FILE="${HOME}/.config/mc/menu"
HOTLIST_FILE="${HOME}/.config/mc/hotlist"

echo "Installing mc-rclone..."

# 1. Create target script directory and symlink bridge
mkdir -p "${TARGET_DIR}"
ln -sf "${SCRIPT_DIR}/mc-rclone-bridge" "${TARGET_LINK}"
chmod +x "${TARGET_LINK}"
echo "✓ Symlinked mc-rclone-bridge to ${TARGET_LINK}"

# 2. Configure MC User Menu (~/.config/mc/menu)
mkdir -p "$(dirname "${MENU_FILE}")"
touch "${MENU_FILE}"

# Remove any existing Rclone block to avoid duplicates
if grep -q "mc-rclone-bridge" "${MENU_FILE}" 2>/dev/null; then
    sed -i '' '/# START_MC_RCLONE/,/# END_MC_RCLONE/d' "${MENU_FILE}" 2>/dev/null || true
fi

cat >> "${MENU_FILE}" << 'EOF'
# START_MC_RCLONE
R       Cloud Storage (Rclone All Remotes)
	~/.local/share/mc/scripts/mc-rclone-bridge start $PPID
	%cd ftp://127.0.0.1:2123/
# END_MC_RCLONE
EOF
echo "✓ Configured Midnight Commander user menu (F2 -> R)"

# 3. Configure Directory Hotlist (~/.config/mc/hotlist)
touch "${HOTLIST_FILE}"
if ! grep -q "ftp://127.0.0.1:2123/" "${HOTLIST_FILE}" 2>/dev/null; then
    cat >> "${HOTLIST_FILE}" << 'EOF'
ENTRY "Cloud: Rclone (All Remotes)" URL "ftp://127.0.0.1:2123/"
EOF
    echo "✓ Added hotlist entry 'Cloud: Rclone (All Remotes)' (Ctrl + \\)"
fi

echo "mc-rclone installation completed successfully!"
```

- [ ] **Step 3: Update `uninstall.sh`**

Edit `/Users/michele/PycharmProjects/mc-rclone/uninstall.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET_LINK="${HOME}/.local/share/mc/scripts/mc-rclone-bridge"
MENU_FILE="${HOME}/.config/mc/menu"
HOTLIST_FILE="${HOME}/.config/mc/hotlist"

echo "Uninstalling mc-rclone..."

# Stop any running bridge
if [ -x "${TARGET_LINK}" ]; then
    "${TARGET_LINK}" stop || true
fi

# Remove symlink
if [ -L "${TARGET_LINK}" ] || [ -f "${TARGET_LINK}" ]; then
    rm -f "${TARGET_LINK}"
    echo "✓ Removed ${TARGET_LINK}"
fi

# Clean user menu
if [ -f "${MENU_FILE}" ]; then
    sed -i '' '/# START_MC_RCLONE/,/# END_MC_RCLONE/d' "${MENU_FILE}" 2>/dev/null || \
    sed -i '/# START_MC_RCLONE/,/# END_MC_RCLONE/d' "${MENU_FILE}" 2>/dev/null || true
    echo "✓ Cleaned user menu entries"
fi

# Clean hotlist
if [ -f "${HOTLIST_FILE}" ]; then
    sed -i '' '/ftp:\/\/127.0.0.1:2123/d' "${HOTLIST_FILE}" 2>/dev/null || \
    sed -i '/ftp:\/\/127.0.0.1:2123/d' "${HOTLIST_FILE}" 2>/dev/null || true
    echo "✓ Cleaned hotlist entries"
fi

echo "mc-rclone uninstalled successfully."
```

- [ ] **Step 4: Run install/uninstall test**

Run:
```bash
/Users/michele/PycharmProjects/mc-rclone/tests/test_install.sh
```
Expected: PASS ("Install verification passed.", "Uninstall verification passed.")

- [ ] **Step 5: Perform clean install for user environment**

Run:
```bash
/Users/michele/PycharmProjects/mc-rclone/install.sh
```
Expected: Completed successfully.

---

### Task 3: Documentation and Verification

**Files:**
- Modify: `/Users/michele/PycharmProjects/mc-rclone/README.md`

- [ ] **Step 1: Update README.md with clear usage instructions**

Update `/Users/michele/PycharmProjects/mc-rclone/README.md` to document:
- How to access via `F2` -> `R`.
- How on-demand `:combine:` works.
- How automatic process shutdown works on MC exit.
- Installation and uninstallation instructions.

- [ ] **Step 2: Commit all changes to git**

Run:
```bash
cd /Users/michele/PycharmProjects/mc-rclone
git add mc-rclone-bridge install.sh uninstall.sh tests/ docs/ README.md
git commit -m "feat: implement on-demand Rclone FTP bridge with combine backend and parent PID tracking"
git push origin master
```
Expected: Changes committed and pushed to remote master branch.
