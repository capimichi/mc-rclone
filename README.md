# mc-rclone

Seamless **Rclone** Virtual File System (`extfs`) plugin for **GNU Midnight Commander (`mc`)**.

Browse, copy, view, and manage files across any cloud storage supported by Rclone (Google Drive, Dropbox, OneDrive, S3, SFTP, WebDAV, etc.) directly inside Midnight Commander's dual-pane interface—**100% portable, with zero background daemons, zero external wrappers, and zero FUSE required**.

---

## ✨ Features

- **100% Portable**: Just a standard Midnight Commander `extfs` plugin (`rclone+`). Works identically on **macOS**, **Linux** (Debian, Ubuntu, Arch, Fedora, Alpine), and **BSD**.
- **No Background Daemons**: No `launchd`, no `systemd`, no sentinels, no open ports, and no memory overhead when MC is closed.
- **Untouched MC Binary**: Your system `mc` binary remains 100% original. No wrappers, aliases, or binary replacement.
- **Fast Smart Caching**: Automatically reads your `~/.config/rclone/rclone.conf` in 1ms. Caches directory structures locally (`~/.cache/mc/rclone/`) so reopening remotes takes under 60 milliseconds.
- **Dual-Pane Cloud-to-Cloud Transfers**: Open Google Drive on the left panel and Dropbox on the right panel, and copy files directly with `F5`.
- **Full File Management**: Supports viewing (`F3`), downloading/copying (`F5`), deleting (`F8`), and creating directories (`F7`).

---

## 🚀 Installation

### 1. Requirements

- [GNU Midnight Commander](https://midnight-commander.org/) (`mc`)
- [Rclone](https://rclone.org/) configured with your remotes (`rclone config`)
- Python 3.7+

### 2. Install Plugin

Clone this repository and run `./install.sh`:

```bash
git clone https://github.com/capimichi/mc-rclone.git
cd mc-rclone
./install.sh
```

What `install.sh` does:
1. Links `rclone+` into your standard MC extension directory: `~/.local/share/mc/extfs.d/rclone+`
2. Adds a bookmark to your MC Directory Hotlist (`~/.config/mc/hotlist`).

---

## 🖥️ Usage

### Inside Midnight Commander

1. Launch standard Midnight Commander:
   ```bash
   mc
   ```
2. Press **`Ctrl + \`** (Directory Hotlist) and select **`Cloud: Rclone (All Remotes)`**.
   *(Or simply navigate to `/ #rclone+` in MC)*.
3. You will see all your configured Rclone cloud remotes as top-level directories:
   - `dropbox-michele/`
   - `googledrive-capimichi/`
   - `home-fs/`
   - ...
4. Press **Enter** on any remote to browse files and folders on-demand!

### Dual-Panel Transfers

- Open `/#rclone+/googledrive-capimichi` on the left panel.
- Open `/#rclone+/dropbox-michele` on the right panel.
- Press **`F5`** to copy files directly between clouds!

---

## ⚙️ Configuration (Optional)

You can customize behavior via `~/.config/mc/rclone.ini` or environment variables:

```ini
[rclone]
# Maximum depth for directory indexing (default: 1)
max_depth = 1

# Cache time-to-live in seconds (default: 300 = 5 minutes)
cache_ttl = 300

# Connection timeout per remote in seconds (default: 2)
timeout = 2

# Limit to specific remotes (default: all configured in rclone.conf)
# remotes = googledrive-capimichi, dropbox-michele
```

---

## 🗑️ Uninstallation

To completely remove the plugin:

```bash
./uninstall.sh
```

---

## 📄 License

GPLv3. See [LICENSE](LICENSE) for details.
