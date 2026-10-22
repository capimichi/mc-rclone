# mc-rclone Refactor, XDG Config, and VFS Cache Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Clean up obsolete ExtFS files, consolidate the bridge executable into `mc-rclone`, add XDG configuration support (`config.ini`) with VFS cache controls, and implement a multi-instance MC watchdog.

**Architecture:** A standalone Python 3 standard library script (`mc-rclone`) that reads `~/.config/mc-rclone/config.ini`, parses `~/.config/rclone/rclone.conf` with rapid SFTP health probing, and runs `rclone serve ftp :combine:` with configurable VFS caching. A background watchdog keeps the server alive as long as any user `mc` instance is running.

**Tech Stack:** Python 3 (standard library: `configparser`, `socket`, `subprocess`, `os`, `signal`, `sys`, `pathlib`), Midnight Commander (MC 4.8.x), Rclone (`serve ftp :combine:`), Pytest, Bash.

## Global Constraints
- System `mc` binary must remain untouched.
- Zero external pip dependencies; standard library Python 3 only.
- 100% cross-platform (macOS, Linux, BSD).
- Configuration comments strictly in English.
- Loopback FTP (`127.0.0.1:2123`) with zero prompt/authentication overhead.

---

### Task 1: Repository Cleanup and Binary Consolidation

**Files:**
- Delete: `/Users/michele/PycharmProjects/mc-rclone/mc-rclone` (deprecated ExtFS script)
- Delete: `/Users/michele/PycharmProjects/mc-rclone/rclone+` (deprecated ExtFS script)
- Delete: `/Users/michele/PycharmProjects/mc-rclone/mc.menu.snippet` (deprecated snippet)
- Rename: `/Users/michele/PycharmProjects/mc-rclone/mc-rclone-bridge` -> `/Users/michele/PycharmProjects/mc-rclone/mc-rclone`

**Interfaces:**
- Produces: Executable `/Users/michele/PycharmProjects/mc-rclone/mc-rclone` with executable permissions (`chmod +x`).

- [ ] **Step 1: Remove obsolete files and git-rename bridge script**

Run:
```bash
cd /Users/michele/PycharmProjects/mc-rclone
git rm mc-rclone rclone+ mc.menu.snippet
git mv mc-rclone-bridge mc-rclone
chmod +x mc-rclone
```
Expected: git staging clean rename of `mc-rclone-bridge` to `mc-rclone` and removal of 3 obsolete files.

- [ ] **Step 2: Verify git status and file permissions**

Run:
```bash
git status --short
test -x mc-rclone && echo "EXECUTABLE OK"
```
Expected: `D mc-rclone`, `D mc.menu.snippet`, `D rclone+`, `R mc-rclone-bridge -> mc-rclone`, and `EXECUTABLE OK`.

---

### Task 2: Configuration Module and Default Generator (`config.ini`)

**Files:**
- Modify: `/Users/michele/PycharmProjects/mc-rclone/mc-rclone`
- Modify: `/Users/michele/PycharmProjects/mc-rclone/tests/test_bridge.py`

**Interfaces:**
- Produces: `load_or_create_config(config_path: Path) -> dict` returning parsed configuration dictionary with fallback defaults:
  - `bind_address`: str (default `"127.0.0.1"`)
  - `port`: int (default `2123`)
  - `cache_mode`: str (default `"writes"`)
  - `cache_max_size`: str (default `"10G"`)
  - `cache_max_age`: str (default `"24h"`)
  - `dir_cache_time`: str (default `"5m"`)
  - `sftp_probe_timeout`: float (default `0.2`)

- [ ] **Step 1: Write failing test in `tests/test_bridge.py` for config loading and generation**

Add to `/Users/michele/PycharmProjects/mc-rclone/tests/test_bridge.py`:
```python
def test_load_or_create_config_default(tmp_path):
    import importlib.util
    spec = importlib.util.spec_from_file_location("mc_rclone", "mc-rclone")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    cfg_file = tmp_path / "config.ini"
    cfg = mod.load_or_create_config(cfg_file)

    assert cfg_file.exists()
    assert cfg["bind_address"] == "127.0.0.1"
    assert cfg["port"] == 2123
    assert cfg["cache_mode"] == "writes"
    assert cfg["cache_max_size"] == "10G"
    assert cfg["cache_max_age"] == "24h"
    assert cfg["dir_cache_time"] == "5m"
    assert cfg["sftp_probe_timeout"] == 0.2


def test_load_custom_config(tmp_path):
    import importlib.util
    spec = importlib.util.spec_from_file_location("mc_rclone", "mc-rclone")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    cfg_file = tmp_path / "config.ini"
    cfg_file.write_text("""
[server]
bind_address = 127.0.0.1
port = 2500

[vfs]
cache_mode = full
cache_max_size = 50G
cache_max_age = 7d
dir_cache_time = 15m

[network]
sftp_probe_timeout = 0.5
""")
    cfg = mod.load_or_create_config(cfg_file)
    assert cfg["port"] == 2500
    assert cfg["cache_mode"] == "full"
    assert cfg["cache_max_size"] == "50G"
    assert cfg["sftp_probe_timeout"] == 0.5
```

- [ ] **Step 2: Run test to verify failure**

Run:
```bash
pytest tests/test_bridge.py::test_load_or_create_config_default
```
Expected: FAIL with `AttributeError: module 'mc_rclone' has no attribute 'load_or_create_config'`

- [ ] **Step 3: Implement `load_or_create_config` in `mc-rclone`**

In `/Users/michele/PycharmProjects/mc-rclone/mc-rclone`:
```python
CONFIG_DIR = Path.home() / ".config" / "mc-rclone"
CONFIG_FILE = CONFIG_DIR / "config.ini"

DEFAULT_CONFIG_CONTENT = """# mc-rclone configuration file

[server]
# Local IP address to bind the FTP server (loopback for security)
bind_address = 127.0.0.1

# Local FTP port used by rclone and configured in Midnight Commander hotlist
port = 2123

[vfs]
# VFS cache mode: off | minimal | writes | full
# - writes: Modified or copied files are buffered locally and uploaded in background (recommended)
# - full: Caches both reads and writes; enables random seeking for large media/archive files
cache_mode = writes

# Maximum size of local VFS disk cache (e.g. 5G, 10G, 50G, off)
cache_max_size = 10G

# Maximum age of cached files before automatic eviction (e.g. 24h, 7d)
cache_max_age = 24h

# Directory listing cache duration (instant directory navigation without repeated API calls)
dir_cache_time = 5m

[network]
# Socket connection timeout in seconds for probing SFTP/SSH remotes
# Unreachable or offline remotes are automatically skipped to prevent rclone hangs
sftp_probe_timeout = 0.2
"""

DEFAULTS = {
    "bind_address": "127.0.0.1",
    "port": 2123,
    "cache_mode": "writes",
    "cache_max_size": "10G",
    "cache_max_age": "24h",
    "dir_cache_time": "5m",
    "sftp_probe_timeout": 0.2,
}


def load_or_create_config(config_path: Path = CONFIG_FILE) -> dict:
    if not config_path.exists():
        try:
            config_path.parent.mkdir(parents=True, exist_ok=True)
            config_path.write_text(DEFAULT_CONFIG_CONTENT)
        except OSError:
            pass  # Fall back to internal defaults if unable to write
        return DEFAULTS.copy()

    parser = configparser.ConfigParser()
    try:
        parser.read(config_path)
    except Exception:
        return DEFAULTS.copy()

    return {
        "bind_address": parser.get("server", "bind_address", fallback=DEFAULTS["bind_address"]),
        "port": parser.getint("server", "port", fallback=DEFAULTS["port"]),
        "cache_mode": parser.get("vfs", "cache_mode", fallback=DEFAULTS["cache_mode"]),
        "cache_max_size": parser.get("vfs", "cache_max_size", fallback=DEFAULTS["cache_max_size"]),
        "cache_max_age": parser.get("vfs", "cache_max_age", fallback=DEFAULTS["cache_max_age"]),
        "dir_cache_time": parser.get("vfs", "dir_cache_time", fallback=DEFAULTS["dir_cache_time"]),
        "sftp_probe_timeout": parser.getfloat("network", "sftp_probe_timeout", fallback=DEFAULTS["sftp_probe_timeout"]),
    }
```

- [ ] **Step 4: Run tests to verify pass**

Run:
```bash
pytest tests/test_bridge.py -k "config" -v
```
Expected: PASS for both config tests.

---

### Task 3: VFS Cache Flag Integration & Command Generation

**Files:**
- Modify: `/Users/michele/PycharmProjects/mc-rclone/mc-rclone`
- Modify: `/Users/michele/PycharmProjects/mc-rclone/tests/test_bridge.py`

**Interfaces:**
- Produces: `build_rclone_cmd(config: dict, upstreams: str) -> list[str]`

- [ ] **Step 1: Write failing test for `build_rclone_cmd`**

Add to `tests/test_bridge.py`:
```python
def test_build_rclone_cmd():
    import importlib.util
    spec = importlib.util.spec_from_file_location("mc_rclone", "mc-rclone")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    cfg = {
        "bind_address": "127.0.0.1",
        "port": 2123,
        "cache_mode": "writes",
        "cache_max_size": "10G",
        "cache_max_age": "24h",
        "dir_cache_time": "5m",
        "sftp_probe_timeout": 0.2,
    }
    cmd = mod.build_rclone_cmd(cfg, "rem1=rem1: rem2=rem2:")
    assert cmd == [
        "rclone", "serve", "ftp",
        "--addr", "127.0.0.1:2123",
        "--vfs-cache-mode", "writes",
        "--vfs-cache-max-size", "10G",
        "--vfs-cache-max-age", "24h",
        "--dir-cache-time", "5m",
        "--combine-upstreams", "rem1=rem1: rem2=rem2:",
        ":combine:"
    ]
```

- [ ] **Step 2: Run test to verify failure**

Run:
```bash
pytest tests/test_bridge.py::test_build_rclone_cmd
```
Expected: FAIL with `AttributeError: module 'mc_rclone' has no attribute 'build_rclone_cmd'`

- [ ] **Step 3: Implement `build_rclone_cmd` in `mc-rclone`**

In `/Users/michele/PycharmProjects/mc-rclone/mc-rclone`:
```python
def build_rclone_cmd(cfg: dict, upstreams: str) -> list[str]:
    return [
        "rclone", "serve", "ftp",
        "--addr", f"{cfg['bind_address']}:{cfg['port']}",
        "--vfs-cache-mode", cfg["cache_mode"],
        "--vfs-cache-max-size", cfg["cache_max_size"],
        "--vfs-cache-max-age", cfg["cache_max_age"],
        "--dir-cache-time", cfg["dir_cache_time"],
        "--combine-upstreams", upstreams,
        ":combine:",
    ]
```

- [ ] **Step 4: Run test to verify pass**

Run:
```bash
pytest tests/test_bridge.py::test_build_rclone_cmd -v
```
Expected: PASS.

---

### Task 4: Multi-Instance Watchdog & Lifecycle Management

**Files:**
- Modify: `/Users/michele/PycharmProjects/mc-rclone/mc-rclone`
- Modify: `/Users/michele/PycharmProjects/mc-rclone/tests/test_bridge.py`

**Interfaces:**
- Produces: `count_user_mc_instances() -> int`
- Produces: `watchdog_loop(server_pid: int)`: checks `count_user_mc_instances()`; if `0`, terminates server and cleans PID files.
- Modifies `start_bridge()` to use config and launch watchdog.

- [ ] **Step 1: Write unit test for `count_user_mc_instances`**

Add to `tests/test_bridge.py`:
```python
def test_count_user_mc_instances(monkeypatch):
    import importlib.util
    spec = importlib.util.spec_from_file_location("mc_rclone", "mc-rclone")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)

    # Mock subprocess output for ps
    monkeypatch.setattr("subprocess.check_output", lambda *a, **k: b"bash\nmc\npython\nmc\n")
    assert mod.count_user_mc_instances() == 2

    monkeypatch.setattr("subprocess.check_output", lambda *a, **k: b"bash\nvim\n")
    assert mod.count_user_mc_instances() == 0
```

- [ ] **Step 2: Run test to verify failure**

Run:
```bash
pytest tests/test_bridge.py::test_count_user_mc_instances
```
Expected: FAIL with `AttributeError: module 'mc_rclone' has no attribute 'count_user_mc_instances'`

- [ ] **Step 3: Implement `count_user_mc_instances` and multi-instance watchdog in `mc-rclone`**

In `/Users/michele/PycharmProjects/mc-rclone/mc-rclone`:
```python
def count_user_mc_instances() -> int:
    try:
        # Cross-platform check: list process command names for current user
        output = subprocess.check_output(
            ["ps", "-u", str(os.getuid()), "-o", "comm="],
            stderr=subprocess.DEVNULL,
            text=True
        )
        count = 0
        for line in output.splitlines():
            base = os.path.basename(line.strip())
            if base in ("mc", "mc.real"):
                count += 1
        return count
    except Exception:
        # Fallback: if ps fails, return 1 to avoid premature termination
        return 1


def watchdog_loop(server_pid: int):
    while True:
        time.sleep(2)
        # Check if server process itself died
        try:
            os.kill(server_pid, 0)
        except OSError:
            break

        # Check active MC instances
        if count_user_mc_instances() == 0:
            try:
                os.kill(server_pid, signal.SIGTERM)
            except OSError:
                pass
            break

    if PID_FILE.exists():
        PID_FILE.unlink(missing_ok=True)
```

- [ ] **Step 4: Run test to verify pass**

Run:
```bash
pytest tests/test_bridge.py::test_count_user_mc_instances -v
```
Expected: PASS.

---

### Task 5: Installer and Uninstaller Updates

**Files:**
- Modify: `/Users/michele/PycharmProjects/mc-rclone/install.sh`
- Modify: `/Users/michele/PycharmProjects/mc-rclone/uninstall.sh`
- Modify: `/Users/michele/PycharmProjects/mc-rclone/tests/test_install.sh`

**Interfaces:**
- `install.sh`: installs `mc-rclone` to `~/.local/share/mc/scripts/mc-rclone` and `~/.local/bin/mc-rclone`. Generates `~/.config/mc-rclone/config.ini` if missing. Injects menu (`R`, `S`, `?`) and hotlist.
- `uninstall.sh`: cleanly removes all traces and restores MC config.

- [ ] **Step 1: Update `install.sh`**

Ensure `install.sh`:
- Copies `mc-rclone` instead of `mc-rclone-bridge`.
- Calls `mc-rclone` to generate the default `config.ini` if missing.
- Reads `port` from `config.ini` (defaulting to 2123) for the Hotlist URL.
- Configures menu with `start`, `stop`, `status` (`?`).

- [ ] **Step 2: Update `uninstall.sh`**

Ensure `uninstall.sh`:
- Stops running `mc-rclone`.
- Removes `~/.local/share/mc/scripts/mc-rclone` and `~/.local/bin/mc-rclone`.
- Reverts `~/.config/mc/menu` and `~/.config/mc/hotlist`.

- [ ] **Step 3: Run isolated install test `tests/test_install.sh`**

Run:
```bash
bash tests/test_install.sh
```
Expected: Install and uninstall pass with 100% success in sandbox environment.

---

### Task 6: Documentation and Final End-to-End Verification

**Files:**
- Modify: `/Users/michele/PycharmProjects/mc-rclone/README.md`
- Run: `pytest tests/`

- [ ] **Step 1: Update README.md with configuration and multi-instance usage**

Document:
- `~/.config/mc-rclone/config.ini` and its VFS cache options.
- The multi-instance MC watchdog behavior.
- Clean 2-step workflow: `F2 -> R` to start, `Ctrl + \` to connect.

- [ ] **Step 2: Run full test suite**

Run:
```bash
cd /Users/michele/PycharmProjects/mc-rclone
pytest -v
bash tests/test_install.sh
```
Expected: All tests pass.

- [ ] **Step 3: Run local installation on user machine**

Run:
```bash
./install.sh
```
Expected: Installs `mc-rclone` cleanly into user's environment.
