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

AGENT="${HOME}/.local/bin/google-drive-agent"
CONFIG_HOME="${XDG_CONFIG_HOME:-${HOME}/.config}"

if [ -x "${AGENT}" ]; then
    # The agent knows the configured mount path and XDG locations.
    "${AGENT}" service remove || true
    "${AGENT}" unmount || true
    "${AGENT}" bookmark remove || true
else
    # Fallback for a partially removed install: default locations only.
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user disable --now google-drive.service 2>/dev/null || true
    fi
    if command -v fusermount3 >/dev/null 2>&1; then
        fusermount3 -u "${HOME}/GoogleDrive" 2>/dev/null || true
    elif command -v fusermount >/dev/null 2>&1; then
        fusermount -u "${HOME}/GoogleDrive" 2>/dev/null || true
    fi
    GTK_BM="${CONFIG_HOME}/gtk-3.0/bookmarks"
    if [ -f "${GTK_BM}" ]; then
        # Remove only our exact entry, not every line mentioning "GoogleDrive".
        grep -vxF "file://${HOME}/GoogleDrive Google Drive" "${GTK_BM}" > "${GTK_BM}.tmp" || true
        cat "${GTK_BM}.tmp" > "${GTK_BM}" && rm -f "${GTK_BM}.tmp"
    fi
fi

# Remove systemd service and autostart entry (no-op if already removed above)
rm -f "${CONFIG_HOME}/systemd/user/google-drive.service"
rm -f "${CONFIG_HOME}/autostart/google-drive-agent.desktop"
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
fi

# Remove desktop entries
rm -f "${XDG_DATA_HOME:-${HOME}/.local/share}/applications/google-drive.desktop"

# Remove icons
rm -rf "${CONFIG_HOME}/google-drive-agent/icons"
rm -f "${XDG_DATA_HOME:-${HOME}/.local/share}/icons/hicolor/128x128/apps/google-drive.png"
rm -f "${XDG_DATA_HOME:-${HOME}/.local/share}/icons/hicolor/scalable/apps/google-drive.svg"

# Remove binary
rm -f "${AGENT}"

log_success "Google Drive Desktop Agent has been uninstalled."
echo -e "\nNote: Your configuration in ${CONFIG_HOME}/google-drive-agent and cached files were kept intact."
echo -e "To completely purge everything, delete: ${CONFIG_HOME}/google-drive-agent, ${XDG_CACHE_HOME:-${HOME}/.cache}/google-drive-agent"
echo -e "and ${XDG_CACHE_HOME:-${HOME}/.cache}/rclone, and run: rclone config delete gdrive\n"
