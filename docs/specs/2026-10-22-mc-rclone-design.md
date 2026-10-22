# Design Specification: MC Rclone Cloud Bridge

**Date:** 2026-10-22  
**Target Application:** GNU Midnight Commander (`mc`)  
**Backend:** Rclone (`rclone serve ftp` with `:combine:`)  
**Repository:** [mc-rclone](https://github.com/capimichi/mc-rclone)

---

## 1. Problem Statement & Motivation

GNU Midnight Commander users need to browse, inspect, transfer, and organize files across multiple cloud storage remotes (Dropbox, Google Drive, SFTP, S3, etc.) seamlessly from standard dual panels.

Prior attempts faced two critical friction points:
1. **ExtFS Initial Scan Bottleneck:** Midnight Commander's ExtFS architecture requires an exhaustive recursive file list (`list`) at root entry. For large cloud repositories, this causes unacceptable multi-second or multi-minute freezes at "minute zero".
2. **System Pollution & Portability Issues:** Workarounds involving OS-specific background daemons (`launchd`, `systemd`), sentinel watchers, or replacement binaries for `mc` broke portability across macOS, Linux, and BSD, leaving unwanted lingering processes.

---

## 2. Solution Overview

The **MC Rclone Cloud Bridge** connects Midnight Commander's native FTP Virtual File System (VFS) to Rclone's internal `:combine:` backend via an on-demand, self-contained launcher triggered directly from MC's User Menu (`F2`).

### Key Architectural Benefits
- **Zero Pre-Crawl (Instant Entry):** The root view only exposes virtual remote names. Cloud API calls occur strictly on-demand per visited directory.
- **Infinite Directory Depth:** Deep subdirectories load on-the-fly without recursion limits or timeouts.
- **Zero Daemons / Zero System Footprint:** No background system services, no open ports when MC is not running.
- **Automatic Lifecycle Management:** The server binds to Midnight Commander's process ID (`$PPID`). When MC terminates, the server process cleans itself up immediately.
- **100% Cross-Platform:** Pure drop-in shell/python script compatible with macOS, Linux, and BSD.

---

## 3. Architecture & Data Flow

```
+-------------------------------------------------------------+
|                   GNU Midnight Commander                    |
|                                                             |
|   Left Panel: /Users/michele/Work                           |
|   Right Panel: ftp://127.0.0.1:2123/                        |
|     ├── dropbox-michele/         (lazy queried on enter)    |
|     ├── googledrive-capimichi/   (lazy queried on enter)    |
|     └── home/                    (lazy queried on enter)    |
+-------------------------------------------------------------+
               │                                ▲
  Press 'F2'   │ User Menu executes:            │ Native FTP VFS
  selects 'R'  │ mc-rclone-bridge start &       │ (F3 view, F5 copy,
               │ %cd ftp://127.0.0.1:2123/      │  F7 mkdir, F8 rm)
               ▼                                │
+─────────────────────────────────────────────────────────────+
|               mc-rclone-bridge (Launcher)                   |
|  1. Parse rclone.conf (1 ms)                                |
|  2. If already running on 2123 -> return 0                  |
|  3. Spawns rclone serve ftp with :combine: upstreams        |
|  4. Starts background watcher bound to MC PPID              |
+─────────────────────────────────────────────────────────────+
                               │
                               ▼
+─────────────────────────────────────────────────────────────+
|       Rclone In-Memory Process (PID bound to MC)            |
|       rclone serve ftp --addr 127.0.0.1:2123 :combine:      |
+─────────────────────────────────────────────────────────────+
                               │
                               ▼ (Only for active directory)
                 Remote Cloud Providers APIs
```

---

## 4. Component Details

### 4.1. Launcher: `mc-rclone-bridge`
- **Location:** `~/.local/share/mc/scripts/mc-rclone-bridge` (or cloned repository).
- **Subcommands:**
  - `start`: Starts the FTP server if not already running on `127.0.0.1:2123`, waiting up to 1 second for socket readiness before returning 0.
  - `stop`: Explicitly terminates running server instances.
  - `status`: Reports running status, active port, and bound parent PID.
- **Dynamic Configuration Discovery:**
  - Automatically identifies `rclone.conf` (respects `~/.config/rclone/rclone.conf` and custom paths).
  - Extracts all active remotes and compiles the `--combine-upstreams` argument:
    `"remote1=remote1: remote2=remote2: ..."`
- **Parent Process Tracking (Clean Exit):**
  - Acquires Midnight Commander's PID from `$PPID` or caller environment.
  - Forks a lightweight watchdog thread/subprocess that polls every 2 seconds. Once MC exits, it kills the `rclone serve` process and removes PID/socket files.
- **Idle Timeout (Safety Net):**
  - If no FTP requests are handled for 15 minutes, the server shuts down automatically to prevent orphaned processes in abnormal exit scenarios.

### 4.2. Midnight Commander Integration

#### User Menu (`~/.config/mc/menu`)
Appends a clean entry in the user menu:
```ini
R       Cloud Storage (Rclone All Remotes)
        ~/.local/share/mc/scripts/mc-rclone-bridge start
        %cd ftp://127.0.0.1:2123/
```
*Behavior:*
1. User presses `F2` then `R`.
2. MC executes `mc-rclone-bridge start`.
3. MC executes `%cd ftp://127.0.0.1:2123/`, instantly displaying the root remotes list.

#### Hotlist Support (`~/.config/mc/hotlist`)
Adds a directory hotlist bookmark (`Ctrl + \`):
```ini
ENTRY "Cloud: Rclone (All Remotes)" URL "ftp://127.0.0.1:2123/"
```
*Behavior:* When the server has been activated during the session, the hotlist allows immediate one-keystroke navigation back to cloud remotes.

---

## 5. Performance & Resource Characteristics

- **Startup Latency:** < 200 ms to launch server and switch panel directory.
- **Subdirectory Navigation:** Real-time on-demand querying (`LIST /subfolder`).
- **RAM Consumption:** ~25 MB to 35 MB total for Rclone. No full trees are held in memory.
- **Disk Footprint:** 0 bytes cached locally; streaming buffer only during active transfers.

---

## 6. Installation & Portability

### `install.sh`
1. Verifies prerequisites: `mc` and `rclone`.
2. Installs `mc-rclone-bridge` into `~/.local/share/mc/scripts/`.
3. Registers the `R` menu shortcut in `~/.config/mc/menu`.
4. Adds the cloud entry into `~/.config/mc/hotlist`.
5. Requires **no root/sudo privileges**, **no OS-level daemons**, **no modifications to system binaries**.

### `uninstall.sh`
1. Stops any running server instances.
2. Removes installed scripts, menu entry, and hotlist entry.
3. Completely restores original user MC configuration.

---

## 7. Verification & Testing Plan

1. **Clean Installation:** Run `install.sh` on standard macOS and Linux environments.
2. **Menu Activation:** Launch `mc`, press `F2` -> `R`, verify panel switches to `ftp://127.0.0.1:2123/` in under 1 second.
3. **Directory Traversal:** Navigate through deeply nested folders (depth > 5) on multiple remotes (e.g. Dropbox, Google Drive); verify instant on-demand response.
4. **Operations:**
   - View text/image file with `F3`.
   - Copy file between cloud remote and local panel with `F5`.
   - Copy file between two different cloud remotes across panels with `F5`.
   - Create and delete folder with `F7` and `F8`.
5. **Lifecycle Teardown:** Quit MC (`F10`), run `ps aux | grep rclone`, confirm no remaining background processes or listening ports.
