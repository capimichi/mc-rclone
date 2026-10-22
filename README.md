# mc-rclone

Seamless, on-demand **Rclone** Cloud Bridge for **GNU Midnight Commander (`mc`)**.

Browse, copy, view, and manage files across any cloud storage supported by Rclone (Google Drive, Dropbox, OneDrive, S3, SFTP, WebDAV, etc.) directly inside Midnight Commander's dual-pane interface—**100% portable, with zero persistent daemons, zero external wrappers, and zero FUSE required**.

---

## ✨ Features

- **On-Demand Deep Navigation (`:combine:` Backend)**: No initial scan freeze ("minute zero"). The root directory instantly exposes all remotes, and subdirectories are fetched live on-demand with infinite depth.
- **Zero Persistent Daemons**: No `launchd`, no `systemd`, no sentinels, no open ports, and zero memory overhead when MC is closed.
- **Automatic Process Lifecycle**: The local bridge automatically tracks Midnight Commander's process ID (`$PPID`). The moment you exit MC (`F10`), the bridge cleanly terminates itself.
- **Untouched MC Binary**: Your system `mc` binary remains 100% original. No wrappers, aliases, or binary replacement.
- **Dual-Pane Cloud-to-Cloud Transfers**: Open Google Drive on the left panel and Dropbox on the right panel, and copy files directly with `F5`.
- **Full File Management**: Supports viewing (`F3`), downloading/copying (`F5`), deleting (`F8`), and creating directories (`F7`).
- **100% Portable**: Compatible with macOS (Apple Silicon & Intel), Linux (Debian, Ubuntu, Arch, Fedora, Alpine), and BSD.

---

## 🚀 Installation

### 1. Requirements

- [GNU Midnight Commander](https://midnight-commander.org/) (`mc`)
- [Rclone](https://rclone.org/) configured with your remotes (`rclone config`)
- Python 3.8+

### 2. Install

Clone this repository and run `./install.sh`:

```bash
git clone https://github.com/capimichi/mc-rclone.git
cd mc-rclone
./install.sh
```

What `install.sh` does:
1. Links `mc-rclone-bridge` into `~/.local/share/mc/scripts/mc-rclone-bridge`.
2. Adds the shortcut to your MC User Menu (`~/.config/mc/menu`) accessible via **`F2` -> `R`**.
3. Adds a bookmark to your MC Directory Hotlist (`~/.config/mc/hotlist`, `Ctrl + \`).

---

## 🖥️ Usage

### Inside Midnight Commander

1. Launch standard Midnight Commander:
   ```bash
   mc
   ```
2. Press **`F2`** (User Menu) and press **`R`** (*Cloud Storage (Rclone All Remotes)*).
   - In under 0.5s, the bridge activates and switches your panel to `ftp://127.0.0.1:2123/`.
3. You will see all your configured Rclone cloud remotes as top-level directories:
   - `dropbox-michele/`
   - `googledrive-capimichi/`
   - `home/`
   - ...
4. Press **Enter** on any remote to browse files and folders live on-demand.
5. When you exit Midnight Commander (`F10`), the bridge automatically shuts down with zero lingering background processes.

---

## 🧹 Uninstallation

To cleanly remove all links, cache, menu entries, and hotlist entries:

```bash
./uninstall.sh
```

---

## 📄 License

GPL-3.0 License.
