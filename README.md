# mc-rclone

Seamless **Rclone** Virtual File System (`extfs`) integration for **GNU Midnight Commander (`mc`)**.

Browse, copy, move, view, and manage files on any cloud storage supported by Rclone (Google Drive, Dropbox, OneDrive, S3, SFTP, WebDAV, and 40+ more) directly inside Midnight Commander's dual-pane interface—**without needing FUSE, root permissions, or manual background mounts**.

---

## ✨ Features

- **Native VFS integration**: Uses Midnight Commander's built-in `extfs` subsystem.
- **Zero runtime dependencies**: Pure Python 3 standard library (no pip packages or virtualenvs needed).
- **Multi-remote support**: Automatically detects all remotes configured in your `rclone.conf`.
- **Parallel scanning & smart caching**: Uses thread pools to fetch directory trees concurrently and caches results locally in `~/.cache/mc/rclone/` for lightning-fast navigation (< 0.1s).
- **Resilient & fault-tolerant**: Handles offline or unreachable remotes gracefully with per-remote timeouts without blocking other remotes.
- **Full file operations**: Supports viewing, copying in/out, renaming, deleting, and directory creation.

---

## 🚀 Quick Start

### 1. Requirements

- [GNU Midnight Commander](https://midnight-commander.org/) (`mc`)
- [Rclone](https://rclone.org/) configured with at least one remote (`rclone config`)
- Python 3.7+

### 2. Installation

Clone this repository and run the installer:

```bash
git clone https://github.com/capimichi/mc-rclone.git
cd mc-rclone
./install.sh
```

*(This creates a symlink to `rclone+` inside `~/.local/share/mc/extfs.d/`)*.

### 3. Usage

1. Open Midnight Commander:
   ```bash
   mc
   ```
2. Press **`Alt + C`** (or `Esc` followed by `c`) to open the **Quick cd** dialog.
3. Type:
   ```text
   rclone://
   ```
   and press **Enter**.
4. You will see all your configured Rclone remotes as top-level folders. Navigate into any remote to view and manage your files!

---

## ⚙️ Configuration (Optional)

You can customize `mc-rclone` behavior via `~/.config/mc/rclone.ini` (or environment variables):

```ini
[rclone]
# Maximum folder depth to scan per remote (default: 3)
max_depth = 3

# Cache TTL in seconds (default: 300)
cache_ttl = 300

# Network timeout per remote in seconds (default: 6)
timeout = 6

# Filter specific remotes to display (default: all configured remotes)
# remotes = googledrive, dropbox, s3-backup

# Enable debug logging to /tmp/mc-rclone.log
debug = false
```

### Environment Variables

| Variable | Description | Default |
| :--- | :--- | :--- |
| `MC_RCLONE_MAX_DEPTH` | Maximum recursion depth | `3` |
| `MC_RCLONE_CACHE_TTL` | Cache duration in seconds | `300` |
| `MC_RCLONE_TIMEOUT` | Network timeout per remote | `6` |
| `MC_RCLONE_REMOTES` | Comma-separated list of remotes | *(all)* |
| `MC_RCLONE_DEBUG` | Set `1` to enable debug logging | `0` |

---

## ⌨️ F2 Menu Integration (Optional)

To access your cloud storage even faster via the **F2** User Menu, copy the contents of `mc.menu.snippet` into your `~/.config/mc/mc.menu`.

---

## 🗑️ Uninstallation

To remove `mc-rclone`:

```bash
./uninstall.sh
```

---

## 📄 License

GNU General Public License v3.0 ([GPL-3.0](LICENSE)) - Compatible with GNU Midnight Commander.
