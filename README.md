# mc-rclone

Seamless **Rclone** Virtual File System (`extfs`) integration for **GNU Midnight Commander (`mc`)**.

Browse, copy, move, view, and manage files on any cloud storage supported by Rclone (Google Drive, Dropbox, OneDrive, S3, SFTP, WebDAV, and 40+ more) directly inside Midnight Commander's dual-pane interface—**without needing FUSE, root permissions, or manual background mounts**.

---

## ✨ Features

- **Blazing Fast On-Demand Navigation**: Operates on-demand directory-by-directory. Handles cloud remotes with millions of files without freezing, memory leaks, or pre-crawling.
- **Dual-Pane Cloud-to-Cloud Transfers**: Mount Google Drive on the left panel and Dropbox on the right panel, and copy files directly between clouds with `F5`.
- **Zero FUSE Required**: Uses pure local networking on `127.0.0.1`. Works on macOS, Linux, and BSD without kernel extensions (`macFUSE`) or root permissions.
- **Multi-Session & Isolated**: Multiple MC panels and tmux windows can connect to the same remote concurrently. If one remote server goes offline, it never affects the others.
- **Automatic Lifecycle Management**: Start and stop remote servers cleanly via the `mc-rclone` CLI or auto-sync your Midnight Commander Directory Hotlist (`Ctrl+\`).

---

## 🚀 Quick Start

### 1. Requirements

- [GNU Midnight Commander](https://midnight-commander.org/) (`mc`)
- [Rclone](https://rclone.org/) configured with your remotes (`rclone config`)
- Python 3.7+

### 2. Installation

Clone this repository and run the installer:

```bash
git clone https://github.com/capimichi/mc-rclone.git
cd mc-rclone
./install.sh
```

---

## 🖥️ Usage

### Mode A: Interactive Selector (Recommended)

Simply run:

```bash
mc-rclone
```

It displays an interactive menu with all your configured Rclone remotes and their live status:

```text
=== mc-rclone: Cloud Manager for Midnight Commander ===

  [1] ○ dropbox-michele (port 2121)
  [2] ● googledrive-capimichi (port 2122)
  [3] ○ home (port 2123)

  [s] Sync Hotlist (Ctrl+\ bookmarks)
  [x] Stop all servers
  [q] Quit

Select an option [1-3] or command:
```

Select a remote number (e.g. `2`), and it starts the server and launches Midnight Commander directly inside that remote!

### Mode B: Dual-Panel / Cloud-to-Cloud Copying

Start the remotes you need:

```bash
mc-rclone start googledrive-capimichi   # Running on port 2122
mc-rclone start dropbox-michele         # Running on port 2121
```

Then open Midnight Commander with Google Drive on the left and Dropbox on the right:

```bash
mc ftp://127.0.0.1:2122/ ftp://127.0.0.1:2121/
```

Press **`F5`** to copy files directly between clouds!

### Mode C: Inside Midnight Commander (Hotlist / Bookmarks)

Press **`Ctrl + \`** (Directory Hotlist) inside Midnight Commander:
Select any `Cloud: <remote>` entry and press **Enter** to jump straight into that cloud storage.

---

## 🛠️ CLI Reference

| Command | Description |
| :--- | :--- |
| `mc-rclone` | Open the interactive menu |
| `mc-rclone status` | Show all remotes, ports, PIDs, and running status |
| `mc-rclone start <remote>` | Start local server for a specific remote |
| `mc-rclone stop [remote]` | Stop a specific remote or all servers |
| `mc-rclone sync` | Update MC Hotlist (`Ctrl+\`) with all remotes |


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
