# Google Drive Desktop Agent for Linux 🐧☁️

> A native Google Drive for Desktop client and agent for Linux that mirrors the Windows/Mac experience — featuring on-demand streaming, VFS file caching, system tray integration, file manager sidebar bookmarks, and background syncing.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](#)
[![Python](https://img.shields.io/badge/Python-3.8+-brightgreen.svg)](#)

[Leia em Português](README.pt.md)

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

## 🚀 Quick Install (1 Command)

To install directly using `curl`:

```bash
git clone https://github.com/hall9000bowman/google-drive-linux.git
cd google-drive-linux
./install.sh
```

Or run the one-line installer:
```bash
curl -fsSL https://raw.githubusercontent.com/hall9000bowman/google-drive-linux/main/install.sh | bash
```

---

## 🔑 Setup & Authentication

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

# Force cache refresh and sync recent cloud changes
google-drive-agent refresh

# Open Google Drive in your web browser
google-drive-agent open-web

# Manually mount or unmount
google-drive-agent mount
google-drive-agent unmount

# Run the desktop system tray applet
google-drive-agent tray

# Manage systemd background service
google-drive-agent service status
google-drive-agent service start
google-drive-agent service stop
```

---

## ⚙️ Configuration

The agent configuration is stored in `~/.config/google-drive-agent/config.json`:

```json
{
  "remote_name": "gdrive",
  "mount_path": "~/GoogleDrive",
  "vfs_cache_mode": "full",
  "vfs_cache_max_size": "50G",
  "vfs_cache_max_age": "72h",
  "vfs_read_chunk_size": "32M",
  "vfs_read_chunk_size_limit": "2G",
  "buffer_size": "64M",
  "dir_cache_time": "72h",
  "poll_interval": "15s",
  "export_formats": "link.html",
  "rc_port": 5572,
  "client_id": "",
  "client_secret": ""
}
```

- **`mount_path`**: Destination directory for your virtual drive (default: `~/GoogleDrive`).
- **`vfs_cache_max_size`**: Maximum local disk space allowed for cached files (e.g., `25G`, `50G`, `100G`).
- **`export_formats`**: Format for Google Docs (`link.html` opens directly in browser; you can also set `docx,xlsx,pptx`).
- **`client_id` / `client_secret`**: (Optional) Provide your own Google Cloud OAuth credentials for dedicated API quota.

---

## 🛡️ Privacy & Security

- **No Third-Party Servers**: Communications occur directly between your Linux machine and official Google APIs.
- **Zero Tracking**: No telemetry, analytics, or external logging.
- **Safe Secrets**: All tokens are stored locally on your machine in standard secure locations (`~/.config/rclone/rclone.conf`).
- **Open Source**: Fully inspectable Python and Shell code under the MIT license.

---

## 🗑️ Uninstallation

To completely remove the agent and desktop shortcuts:

```bash
./uninstall.sh
```

---

## 📄 License

Released under the [MIT License](LICENSE).
