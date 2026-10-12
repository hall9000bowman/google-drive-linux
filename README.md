# Google Drive Desktop Agent for Linux 🐧☁️

> An unofficial, native Google Drive client and agent for Linux, inspired by the official Windows/Mac desktop app — featuring on-demand streaming, VFS file caching, system tray integration, file manager sidebar bookmarks, and background syncing.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](#)
[![Python](https://img.shields.io/badge/Python-3.8+-brightgreen.svg)](#)

[Leia em Português](README.pt.md)

> [!NOTE]
> **Unofficial project.** This is an independent, community-made tool. It is not affiliated with, endorsed by, or supported by Google. It is built on [rclone](https://rclone.org/).
>
> **Beta software. Use at your own risk.** It has been tested on a limited set of setups. Keep important files backed up and please [report issues](https://github.com/hall9000bowman/google-drive-linux/issues).

---

## 🌟 Key Features

- **On-Demand Streaming (VFS Cache)**: Browse your entire Google Drive without filling up your local storage. Files are downloaded transparently when accessed and cached locally.
- **Bi-Directional Auto-Sync**: Save or edit a file in any local application (LibreOffice, VS Code, GIMP, text editors) and changes automatically upload to the cloud in the background.
- **Fast Change Polling**: Remote changes made on web or mobile appear on your desktop within 15 seconds.
- **Google Docs / Sheets / Slides Support**: Native Google Workspace files are exported as web links that open directly in your default browser on double-click.
- **File Manager Integration**: Automatically bookmarks `Google Drive` in your file manager's sidebar (Nautilus, Dolphin, Thunar, and file dialogs).
- **System Tray Applet**: Real-time status indicator, storage quota display, quick links to open your Drive folder or the web interface, and manual refresh controls.
- **Background Daemon via Systemd**: Runs seamlessly in the background as a `systemd --user` service with auto-start on login and auto-recovery.
- **Zero-Root Installation**: Installs completely into your user space (`~/.local/bin`, `~/.config`). No root or `sudo` required!

---

## 🚀 Quick Install

Clone the repository and run the installer:

```bash
git clone https://github.com/hall9000bowman/google-drive-linux.git
cd google-drive-linux
./install.sh
```

If `rclone` is not installed, the installer downloads the latest release and verifies its SHA-256 checksum and, when `gpg` is available, the rclone release signature before installing it to `~/.local/bin`.

---

## 🔑 Setup & Authentication

> [!IMPORTANT]
> rclone's shared Google Drive client ID is being retired and will stop working during 2026. Before running setup, [create your own Google OAuth client ID](https://rclone.org/drive/#making-your-own-client-id) and put it in `client_id` / `client_secret` in the configuration file (see [Configuration](#%EF%B8%8F-configuration) below). It also gives you a dedicated API quota, so the drive is faster.

After installation, connect your Google Account with:

```bash
google-drive-agent setup
```

1. Your default web browser will open automatically.
2. Sign in to your Google Account and click **Allow**.
3. Google Drive will immediately mount to `~/GoogleDrive` and begin streaming your files!

---

## 💻 CLI Commands

The `google-drive-agent` command-line interface provides complete control:

```bash
# Open Google Drive folder in default file manager (mounts if needed)
google-drive-agent open

# Check connection status, VFS cache stats, and Google Drive storage quota
google-drive-agent status

# Re-read the whole Drive file list in the background (or just one folder)
google-drive-agent refresh
google-drive-agent refresh "Work/Reports"

# Open Google Drive in your web browser
google-drive-agent open-web

# Manually mount or unmount
google-drive-agent mount
google-drive-agent unmount

# Run the desktop system tray applet
google-drive-agent tray

# Manage systemd background service
google-drive-agent service install
google-drive-agent service remove
google-drive-agent service status
google-drive-agent service start
google-drive-agent service stop

# Add or remove the file manager sidebar bookmark
google-drive-agent bookmark add
google-drive-agent bookmark remove
```

When the systemd service is enabled it owns the mount: `mount`, `unmount` and the tray's mount toggle start and stop the service instead of running a second rclone process.

---

## ⚙️ Configuration

The agent configuration is stored in `~/.config/google-drive-agent/config.json` (or under `$XDG_CONFIG_HOME`). The file is kept private (`0600`) because it may contain your OAuth client secret. Changes apply the next time the drive is mounted.

```json
{
  "remote_name": "gdrive",
  "mount_path": "~/GoogleDrive",
  "vfs_cache_mode": "full",
  "vfs_cache_max_size": "50G",
  "vfs_cache_max_age": "72h",
  "vfs_cache_min_free_space": "10G",
  "vfs_read_chunk_size": "32M",
  "vfs_read_chunk_size_limit": "2G",
  "buffer_size": "16M",
  "drive_chunk_size": "64M",
  "dir_cache_time": "72h",
  "poll_interval": "15s",
  "export_formats": "link.html",
  "log_level": "NOTICE",
  "rc_port": 5572,
  "client_id": "",
  "client_secret": ""
}
```

- **`mount_path`**: Destination directory for your virtual drive (default: `~/GoogleDrive`).
- **`vfs_cache_max_size`**: Maximum local disk space allowed for cached files (e.g., `25G`, `50G`, `100G`).
- **`vfs_cache_min_free_space`**: Evict cached files to keep at least this much free space on the cache disk. Set to `""` to disable (needed for very old rclone versions).
- **`buffer_size`**: In-memory read-ahead per open file. Kept small because the VFS cache already stores file data on disk.
- **`drive_chunk_size`**: Upload chunk size. Larger values speed up big uploads but use that much memory per concurrent upload. Set to `""` to use rclone's default.
- **`export_formats`**: Format for Google Docs (`link.html` opens directly in browser; you can also set `docx,xlsx,pptx`).
- **`log_level`**: rclone log verbosity: `DEBUG`, `INFO`, `NOTICE` or `ERROR`.
- **`rc_port`**: Local port for rclone's remote-control API (used by *Refresh*). It is bound to `127.0.0.1` and password-protected.
- **`client_id` / `client_secret`**: Your own Google Cloud OAuth credentials. Strongly recommended; see [Setup & Authentication](#-setup--authentication).

Invalid or unknown values are reported as warnings and replaced with their defaults. A file that isn't valid JSON is never overwritten.

---

## 🩺 Troubleshooting

- **Status overview**: `google-drive-agent status`
- **Logs (systemd service)**: `journalctl --user -u google-drive.service`
- **Logs (manual / tray mount)**: `~/.cache/google-drive-agent/rclone.log`
- **"Transport endpoint is not connected"**: rclone exited unexpectedly. Running `google-drive-agent mount` cleans up the stale mount and mounts again.
- **Refresh says the credentials were rejected**: the drive was mounted by an older version. Unmount and mount again.

---

## 🛡️ Privacy & Security

- **No Third-Party Servers**: Communications occur directly between your Linux machine and official Google APIs.
- **Zero Tracking**: No telemetry, analytics, or external logging.
- **Safe Secrets**: OAuth tokens are stored locally by rclone (`~/.config/rclone/rclone.conf`). The agent's own config and generated credentials are readable only by your user.
- **Protected Local API**: rclone's remote-control API listens only on `127.0.0.1` and requires a random password (stored in `~/.config/google-drive-agent/rc-auth.json`). Other local users and websites open in your browser can't use it to read your token or modify your files. The password is passed to rclone through its environment, so it never appears in the process list.
- **Verified Downloads**: The installer checks the rclone download against its signed release checksums.
- **Open Source**: Fully inspectable Python and Shell code under the MIT license.

---

## 🗑️ Uninstallation

To completely remove the agent, its systemd service, desktop shortcuts and sidebar bookmark:

```bash
./uninstall.sh
```

Your configuration, cache and rclone remote are kept. The uninstaller prints the commands to purge them as well.

---

## ™️ Trademarks

Google Drive™ is a trademark of Google LLC. It is used here only to describe what this tool connects to. The application icon is an original design made for this project and is distributed under the same MIT license.

---

## 📄 License

Released under the [MIT License](LICENSE).
