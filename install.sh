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
ICON_DIR="${CONFIG_DIR}/icons"

mkdir -p "${BIN_DIR}" "${CONFIG_DIR}" "${ICON_DIR}" "${DESKTOP_DIR}"

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
# Release signing key published at https://rclone.org/install/
RCLONE_GPG_KEY="FBF737ECE9F8AB18604BD2AC93935E02FF3B54FA"

install_rclone() {
    local tool arch rclone_arch version zip base tmp_dir gpg_status
    for tool in curl unzip sha256sum; do
        if ! command -v "${tool}" >/dev/null 2>&1; then
            log_error "'${tool}' is required to download rclone. Install it or install rclone from your distro."
            exit 1
        fi
    done

    arch="$(uname -m)"
    case "${arch}" in
        x86_64|amd64) rclone_arch="linux-amd64" ;;
        aarch64|arm64) rclone_arch="linux-arm64" ;;
        *) log_error "Unsupported architecture: ${arch}"; exit 1 ;;
    esac

    version="$(curl -fsSL https://downloads.rclone.org/version.txt | awk '{print $2}')"
    if [[ ! "${version}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        log_error "Could not determine the current rclone version."
        exit 1
    fi
    zip="rclone-${version}-${rclone_arch}.zip"
    base="https://downloads.rclone.org/${version}"

    tmp_dir="$(mktemp -d)"
    RCLONE_TMP_DIR="${tmp_dir}"
    trap 'rm -rf "${RCLONE_TMP_DIR}"' EXIT

    log_info "Downloading rclone ${version} for ${rclone_arch}..."
    curl -fsSL "${base}/${zip}" -o "${tmp_dir}/${zip}"
    curl -fsSL "${base}/SHA256SUMS" -o "${tmp_dir}/SHA256SUMS"

    # Verify the checksum list was signed by the rclone release key.
    if command -v gpg >/dev/null 2>&1; then
        export GNUPGHOME="${tmp_dir}/gnupg"
        mkdir -m 700 "${GNUPGHOME}"
        if gpg --batch --quiet --keyserver hkps://keys.openpgp.org --recv-keys "${RCLONE_GPG_KEY}" >/dev/null 2>&1 \
            || gpg --batch --quiet --keyserver hkps://keyserver.ubuntu.com --recv-keys "${RCLONE_GPG_KEY}" >/dev/null 2>&1; then
            gpg_status="$(gpg --batch --status-fd 1 --verify "${tmp_dir}/SHA256SUMS" 2>/dev/null || true)"
            if ! grep -q "^\[GNUPG:\] VALIDSIG .* ${RCLONE_GPG_KEY}\$" <<<"${gpg_status}"; then
                log_error "GPG signature verification of rclone SHA256SUMS FAILED. Aborting."
                exit 1
            fi
            log_success "rclone release signature verified."
        else
            log_warn "Could not fetch the rclone signing key; verifying SHA-256 checksum only."
        fi
        unset GNUPGHOME
    else
        log_warn "gpg not found; verifying SHA-256 checksum only."
    fi

    if ! (cd "${tmp_dir}" && grep -E "^[0-9a-f]{64}  ${zip}\$" SHA256SUMS | sha256sum -c --status -); then
        log_error "Checksum verification of ${zip} FAILED. Aborting."
        exit 1
    fi
    log_success "rclone checksum verified."

    unzip -q -o "${tmp_dir}/${zip}" -d "${tmp_dir}/extracted"
    install -m 755 "${tmp_dir}/extracted/rclone-${version}-${rclone_arch}/rclone" "${BIN_DIR}/rclone"
    log_success "Installed rclone to ${BIN_DIR}/rclone."
}

if command -v rclone >/dev/null 2>&1; then
    log_success "rclone is already installed ($(rclone version | head -n1))."
elif [ -x "${BIN_DIR}/rclone" ]; then
    log_success "rclone is already installed at ${BIN_DIR}/rclone."
else
    log_info "rclone is not found in PATH. Downloading standalone rclone binary..."
    install_rclone
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

# 5. Default configuration (may hold an OAuth client secret: keep it private)
chmod 700 "${CONFIG_DIR}"
if [ ! -f "${CONFIG_DIR}/config.json" ]; then
    log_info "Creating default configuration..."
    install -m 600 "${SCRIPT_DIR}/config/config.example.json" "${CONFIG_DIR}/config.json"
else
    chmod 600 "${CONFIG_DIR}/config.json"
fi

# 6. Install application launcher
log_info "Registering desktop integration..."
sed "s|google-drive-agent|${BIN_DIR}/google-drive-agent|g; s|Icon=google-drive|Icon=${ICON_DIR}/google-drive.png|g" \
    "${SCRIPT_DIR}/desktop/google-drive.desktop" > "${DESKTOP_DIR}/google-drive.desktop"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${DESKTOP_DIR}" 2>/dev/null || true
fi

# 7. Systemd user service + tray autostart entry (generated by the agent itself)
log_info "Setting up systemd user service and tray autostart..."
"${BIN_DIR}/google-drive-agent" service install --no-start || log_warn "Systemd service setup failed; the tray will mount on login instead."

# 8. File manager sidebar bookmark (uses mount_path from config.json)
log_info "Configuring file manager bookmarks..."
"${BIN_DIR}/google-drive-agent" bookmark add || true

echo ""
log_success "Installation completed successfully!"
echo -e "\n${BOLD}Next Step: Connect your Google Account${RESET}"
echo -e "Run the setup command in your terminal:\n"
echo -e "    ${GREEN}${BOLD}google-drive-agent setup${RESET}\n"
echo -e "Your web browser will open to authenticate. Once approved, Google Drive"
echo -e "will automatically mount and stream files at your configured mount folder"
echo -e "(default: ${BOLD}${HOME}/GoogleDrive${RESET}).\n"
