# mc-rclone

Seamless, on-demand **Rclone** Cloud Bridge for **GNU Midnight Commander (`mc`)**.

Browse, copy, view, and manage files across any cloud storage supported by Rclone (Google Drive, Dropbox, OneDrive, S3, SFTP, WebDAV, etc.) directly inside Midnight Commander's dual-pane interface—**100% portable, with zero persistent daemons, zero external wrappers, and zero FUSE required**.

---

## ✨ Features

- **Independent Multi-Instance Ports**: Each selected remote runs as an isolated Rclone FTP server on its own dedicated loopback port (e.g., `2123`, `2124`...). Hot-adding or removing drives never restarts active servers, ensuring zero TCP socket drops and eliminating Midnight Commander `?` stat errors.
- **Dynamic Hotlist Injection**: Active remotes automatically appear directly in Midnight Commander's Directory Hotlist (`Ctrl + \`). Midnight Commander detects the hotlist file `mtime` modification on-the-fly, reloading active cloud bookmarks instantly without restarting `mc`.
- **Zero Startup Hangs**: SFTP/SSH probe prevents unreachable hosts from blocking startup. Remotes launch independently in parallel in ~0.05s.
- **Configurable VFS Cache**: Native support for Rclone's VFS caching (`writes` or `full`), cache size limits, eviction age, and directory cache times via standard XDG configuration (`~/.config/mc-rclone/config.ini`).
- **Multi-Instance Support**: Open multiple `mc` terminal windows or tmux panes simultaneously; active servers remain available until the last `mc` window closes.
- **Zero Persistent Daemons**: No `launchd`, no `systemd`, no sentinels, no open ports, and zero memory overhead when MC is closed.
- **Untouched MC Binary**: Your system `mc` binary remains 100% original. No wrappers, aliases, or binary replacements.
- **Dual-Pane Cloud-to-Cloud Transfers**: Open Google Drive on the left panel and Dropbox on the right panel, and copy files directly with `F5`.
- **Full File Management**: Supports viewing (`F3`), downloading/copying (`F5`), deleting (`F8`), and creating directories (`F7`).
- **100% Portable**: Compatible with macOS (Apple Silicon & Intel), Linux (Debian, Ubuntu, Arch, Fedora, Alpine), and BSD.

---

## 🚀 Installation

### 1. Requirements

- [GNU Midnight Commander](https://midnight-commander.org/) (`mc`)
- [Rclone](https://rclone.org/) configured with your remotes (`rclone config`)
- Python 3.8+ (standard library only, zero pip dependencies)

### 2. Install

Clone this repository and run `./install.sh`:

```bash
git clone https://github.com/capimichi/mc-rclone.git
cd mc-rclone
./install.sh
```

What `install.sh` does:
1. Installs `mc-rclone` into `~/.local/share/mc/scripts/mc-rclone` and `~/.local/bin/mc-rclone`.
2. Generates default configuration `~/.config/mc-rclone/config.ini` if not already present.
3. Adds shortcut entries to your MC User Menu (`~/.config/mc/menu`) accessible via **`F2`** (`R` to start, `S` to stop, `?` for status). Since a user menu replaces the system one, if `~/.config/mc/menu` does not exist yet it is first seeded from the system `mc.menu`, so the default entries are kept (`uninstall.sh` removes the seeded file again if you have not edited it).
4. Adds a bookmark to your MC Directory Hotlist (`~/.config/mc/hotlist`, `Ctrl + \`).

---

## ⚙️ Configuration

`mc-rclone` is configured via `~/.config/mc-rclone/config.ini` (standard XDG location). Sensible defaults are automatically created on first run:

```ini
[server]
# Base IP address to bind the FTP servers (loopback for security)
bind_address = 127.0.0.1

# Starting port for independent FTP instances (each active remote gets an incremental port)
base_port = 2123

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
```

---

## 🖥️ Usage

### Inside Midnight Commander

1. **Launch standard Midnight Commander:**
   ```bash
   mc
   ```
2. **Select & Mount Remotes (F2 -> R):**
   * Press **`F2`** (User Menu), then select **`R`** (*Select / Mount Cloud Storage*).
   * A full-screen interactive picker opens with real-time filtering:
     - Use **`UP` / `DOWN`** to navigate.
     - Type any letters to search across 150+ remotes instantly.
     - Press **`SPACE`** to toggle `[X]` / `[ ]` on remotes.
     - Press **`ENTER`** to mount selected remotes.
   * Rclone starts or hot-reloads in **~0.3s** on `127.0.0.1:2123`.
3. **Browse Cloud Remotes (Ctrl + \\):**
   * Press **`Ctrl + \`** (Directory Hotlist) and select any active remote (e.g. **`Cloud: googledrive-capimichi`**).
   * Midnight Commander reloads the hotlist instantly upon keypress—no MC restart required.
   * Your active panel connects directly to the dedicated port with full subfolder navigation.
4. **Multi-Window Shared Pool & Dynamic Addition:**
   * Open as many MC windows or tmux panes as you want.
   * If you press **`F2 -> R`** in another window or at any later time, simply toggle additional remotes.
   * New remotes start on separate ports immediately; previously opened drives are never interrupted or severed!
5. **Clean Exit:**
   * When you quit Midnight Commander (**`F10`**), the background server terminates automatically once the last `mc` window closes.
   * You can also check status with **`F2` -> `?`** or unmount/stop manually anytime with **`F2` -> `S`**.

---

### Command Line Interface (CLI)

You can also manage active remotes directly from your terminal:

```bash
# Open interactive curses remote selector
mc-rclone select

# Directly mount specific remotes without UI
mc-rclone select googledrive-capimichi dropbox-michele

# Hot-add a remote to the active pool
mc-rclone add onedrive-michele

# Hot-remove a remote from the active pool
mc-rclone remove googledrive-capimichi

# Check server status and active remotes
mc-rclone status

# Stop server and unmount all remotes
mc-rclone stop
```

---

## 🧪 Testing

To run the full test suite:

```bash
# Run unit tests
pytest -v

# Run isolated sandbox install/uninstall verification
bash tests/test_install.sh
```

---

## 🧹 Uninstallation

To cleanly remove all links, cache, menu entries, and hotlist bookmarks:

```bash
./uninstall.sh
```

---

## 📄 License

GPL-3.0 License.
