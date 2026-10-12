#!/usr/bin/env bash
# ==============================================================================
# Google Drive Desktop Agent for Linux — Automated Installer
# Installs Google Drive for Desktop functionality into the user environment.
# No root/sudo required.
# ==============================================================================

set -euo pipefail

BOLD="\033[1m"
GREEN="\033[32m"
BLUE="\033[34m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

log_info() {
    echo -e "${BLUE}${BOLD}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}${BOLD}[SUCCESS]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}${BOLD}[WARNING]${RESET} $1"
}

log_error() {
    echo -e "${RED}${BOLD}[ERROR]${RESET} $1"
}

echo -e "${BOLD}======================================================${RESET}"
echo -e "${BOLD}     Google Drive Desktop Agent for Linux Installer   ${RESET}"
echo -e "${BOLD}======================================================${RESET}\n"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/google-drive-agent"
DESKTOP_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
AUTOSTART_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/autostart"
SYSTEMD_USER_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/systemd/user"
ICON_DIR="${CONFIG_DIR}/icons"

mkdir -p "${BIN_DIR}" "${CONFIG_DIR}" "${ICON_DIR}" "${DESKTOP_DIR}" "${AUTOSTART_DIR}" "${SYSTEMD_USER_DIR}"

# 1. Dependency verification
log_info "Checking dependencies..."

if ! command -v python3 >/dev/null 2>&1; then
    log_error "Python 3 is required but not installed."
    exit 1
fi

if ! python3 -c "import gi" >/dev/null 2>&1; then
    log_warn "Python GObject (gi) was not detected."
    log_warn "The CLI and mounting will work, but the system tray applet requires 'gi'."
    log_warn "Install it on your distro: "
    log_warn "  Arch/CachyOS: sudo pacman -S python-gobject libappindicator-gtk3"
    log_warn "  Ubuntu/Debian: sudo apt install python3-gi gir1.2-appindicator3-0.1"
    log_warn "  Fedora:        sudo dnf install python3-gobject libappindicator-gtk3"
fi

if ! command -v fusermount3 >/dev/null 2>&1 && ! command -v fusermount >/dev/null 2>&1; then
    log_warn "FUSE (fusermount/fusermount3) is not installed. You may need to install 'fuse3'."
fi

# 2. Check / Install rclone
if command -v rclone >/dev/null 2>&1; then
    log_success "rclone is already installed ($(rclone version | head -n1))."
else
    log_info "rclone is not found in PATH. Downloading standalone rclone binary..."
    ARCH="$(uname -m)"
    case "${ARCH}" in
        x86_64|amd64) RCLONE_ARCH="linux-amd64" ;;
        aarch64|arm64) RCLONE_ARCH="linux-arm64" ;;
        *) log_error "Unsupported architecture: ${ARCH}"; exit 1 ;;
    esac

    TMP_DIR="$(mktemp -d)"
    trap 'rm -rf "${TMP_DIR}"' EXIT

    log_info "Downloading rclone for ${RCLONE_ARCH}..."
    curl -fsSL "https://downloads.rclone.org/rclone-current-${RCLONE_ARCH}.zip" -o "${TMP_DIR}/rclone.zip"
    unzip -q -o "${TMP_DIR}/rclone.zip" -d "${TMP_DIR}/extracted"
    cp "${TMP_DIR}/extracted"/rclone-*-"${RCLONE_ARCH}"/rclone "${BIN_DIR}/rclone"
    chmod +x "${BIN_DIR}/rclone"
    log_success "Installed rclone to ${BIN_DIR}/rclone."
fi

# 3. Install agent executable
log_info "Installing google-drive-agent..."
cp "${SCRIPT_DIR}/bin/google-drive-agent" "${BIN_DIR}/google-drive-agent"
chmod +x "${BIN_DIR}/google-drive-agent"
log_success "Installed executable to ${BIN_DIR}/google-drive-agent."

# 4. Install icons
log_info "Installing application icons..."
cp "${SCRIPT_DIR}/assets/google-drive.png" "${ICON_DIR}/google-drive.png"
if [ -f "${SCRIPT_DIR}/assets/google-drive.svg" ]; then
    cp "${SCRIPT_DIR}/assets/google-drive.svg" "${ICON_DIR}/google-drive.svg"
fi

# System hicolor icons (user level)
HICOLOR_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/icons/hicolor"
mkdir -p "${HICOLOR_DIR}/scalable/apps" "${HICOLOR_DIR}/128x128/apps"
cp "${SCRIPT_DIR}/assets/google-drive.png" "${HICOLOR_DIR}/128x128/apps/google-drive.png"
if [ -f "${SCRIPT_DIR}/assets/google-drive.svg" ]; then
    cp "${SCRIPT_DIR}/assets/google-drive.svg" "${HICOLOR_DIR}/scalable/apps/google-drive.svg"
fi

# 5. Default configuration
if [ ! -f "${CONFIG_DIR}/config.json" ]; then
    log_info "Creating default configuration..."
    cp "${SCRIPT_DIR}/config/config.example.json" "${CONFIG_DIR}/config.json"
fi

# 6. Install desktop files
log_info "Registering desktop integration..."
sed "s|google-drive-agent|${BIN_DIR}/google-drive-agent|g; s|Icon=google-drive|Icon=${ICON_DIR}/google-drive.png|g" \
    "${SCRIPT_DIR}/desktop/google-drive.desktop" > "${DESKTOP_DIR}/google-drive.desktop"

sed "s|google-drive-agent|${BIN_DIR}/google-drive-agent|g; s|Icon=google-drive|Icon=${ICON_DIR}/google-drive.png|g" \
    "${SCRIPT_DIR}/desktop/google-drive-agent.desktop" > "${AUTOSTART_DIR}/google-drive-agent.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
fi

# 7. Install Systemd user service
log_info "Setting up systemd user service..."
cp "${SCRIPT_DIR}/systemd/google-drive.service" "${SYSTEMD_USER_DIR}/google-drive.service"

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable google-drive.service 2>/dev/null || true
    log_success "Systemd user service enabled."
fi

# 8. File manager sidebar bookmarks
log_info "Configuring file manager bookmarks..."
GTK_BM="${XDG_CONFIG_HOME:-${HOME}/.config}/gtk-3.0/bookmarks"
mkdir -p "$(dirname "${GTK_BM}")"
if [ -f "${GTK_BM}" ]; then
    if ! grep -q "GoogleDrive" "${GTK_BM}"; then
        echo "file://${HOME}/GoogleDrive Google Drive" >> "${GTK_BM}"
    fi
else
    echo "file://${HOME}/GoogleDrive Google Drive" > "${GTK_BM}"
fi

# Ensure mount directory exists
mkdir -p "${HOME}/GoogleDrive"

echo ""
log_success "Installation completed successfully!"
echo -e "\n${BOLD}Next Step: Connect your Google Account${RESET}"
echo -e "Run the setup command in your terminal:\n"
echo -e "    ${GREEN}${BOLD}google-drive-agent setup${RESET}\n"
echo -e "Your web browser will open to authenticate. Once approved, Google Drive"
echo -e "will automatically mount and stream files at ${BOLD}${HOME}/GoogleDrive${RESET}.\n"
