#!/usr/bin/env bash
# ==============================================================================
# Google Drive Desktop Agent for Linux — Uninstaller
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
RED="\033[31m"
RESET="\033[0m"

log_info() { echo -e "${BLUE}${BOLD}[INFO]${RESET} $1"; }
log_success() { echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"; }

echo -e "${BOLD}======================================================${RESET}"
echo -e "${BOLD}   Google Drive Desktop Agent — Uninstaller           ${RESET}"
echo -e "${BOLD}======================================================${RESET}\n"

# Stop service and unmount
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user stop google-drive.service 2>/dev/null || true
    systemctl --user disable google-drive.service 2>/dev/null || true
fi

if command -v fusermount3 >/dev/null 2>&1; then
    fusermount3 -u "${HOME}/GoogleDrive" 2>/dev/null || true
elif command -v fusermount >/dev/null 2>&1; then
    fusermount -u "${HOME}/GoogleDrive" 2>/dev/null || true
fi

# Remove systemd service
rm -f "${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user/google-drive.service"
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
fi

# Remove desktop entries
rm -f "${XDG_DATA_HOME:-${HOME}/.local/share}/applications/google-drive.desktop"
rm -f "${XDG_CONFIG_HOME:-${HOME}/.config}/autostart/google-drive-agent.desktop"

# Remove icons
rm -rf "${XDG_CONFIG_HOME:-${HOME}/.config}/google-drive-agent/icons"
rm -f "${XDG_DATA_HOME:-${HOME}/.local/share}/icons/hicolor/128x128/apps/google-drive.png"
rm -f "${XDG_DATA_HOME:-${HOME}/.local/share}/icons/hicolor/scalable/apps/google-drive.svg"

# Remove binary
rm -f "${HOME}/.local/bin/google-drive-agent"

# Remove GTK bookmark
GTK_BM="${XDG_CONFIG_HOME:-${HOME}/.config}/gtk-3.0/bookmarks"
if [ -f "${GTK_BM}" ]; then
    sed -i '/GoogleDrive/d' "${GTK_BM}"
fi

log_success "Google Drive Desktop Agent has been uninstalled."
echo -e "\nNote: Your configuration in ${HOME}/.config/google-drive-agent and cached files were kept intact."
echo -e "To completely purge configurations, delete: ${HOME}/.config/google-drive-agent and ${HOME}/.cache/rclone\n"
