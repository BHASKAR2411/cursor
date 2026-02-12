#!/bin/bash

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_logo() {
    echo -e "${CYAN}"
    cat << "EOF"
   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗      ██████╗ ██████╗  ██████╗
  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗     ██╔══██╗██╔══██╗██╔═══██╗
  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝     ██████╔╝██████╔╝██║   ██║
  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗     ██╔═══╝ ██╔══██╗██║   ██║
  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║     ██║     ██║  ██║╚██████╔╝
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝     ╚═╝     ╚═╝  ╚═╝ ╚═════╝
EOF
    echo -e "${NC}"
}

get_downloads_dir() {
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "$HOME/Downloads"
    else
        if [ -f "$HOME/.config/user-dirs.dirs" ]; then
            . "$HOME/.config/user-dirs.dirs"
            echo "${XDG_DOWNLOAD_DIR:-$HOME/Downloads}"
        else
            echo "$HOME/Downloads"
        fi
    fi
}

get_latest_version() {
    echo -e "${CYAN}ℹ️ Checking latest version...${NC}"
    latest_release=$(curl -s https://api.github.com/repos/BHASKAR2411/cursor/releases/latest) || {
        echo -e "${RED}❌ Cannot get latest version information${NC}"
        exit 1
    }

    VERSION=$(echo "$latest_release" | grep -o '"tag_name": ".*"' | cut -d'"' -f4 | tr -d 'v')

    if [ -z "$VERSION" ]; then
        echo -e "${RED}❌ Failed to parse version${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Found latest version: ${VERSION}${NC}"
}

detect_os() {
    ARCH=$(uname -m)

    if [[ "$(uname)" == "Darwin" ]]; then
        if [[ "$ARCH" == "arm64" ]]; then
            OS_KEY="mac"
            ARCH_KEY="arm64"
        else
            OS_KEY="mac"
            ARCH_KEY="intel"
        fi
        echo -e "${CYAN}ℹ️ Detected macOS ${ARCH}${NC}"

    elif [[ "$(uname)" == "Linux" ]]; then
        if [[ "$ARCH" == "aarch64" || "$ARCH" == "arm64" ]]; then
            OS_KEY="linux"
            ARCH_KEY="arm64"
        else
            OS_KEY="linux"
            ARCH_KEY="x64"
        fi
        echo -e "${CYAN}ℹ️ Detected Linux ${ARCH}${NC}"

    else
        OS_KEY="windows"
        ARCH_KEY=""
        echo -e "${CYAN}ℹ️ Detected Windows${NC}"
    fi
}

install_cursor_free_vip() {
    downloads_dir=$(get_downloads_dir)

    echo -e "${CYAN}ℹ️ Fetching release asset automatically...${NC}"

    release_json=$(curl -s https://api.github.com/repos/BHASKAR2411/cursor/releases/tags/v${VERSION})

    # Try OS + ARCH match first
    asset_url=$(echo "$release_json" | grep browser_download_url | grep -i "$OS_KEY" | grep -i "$ARCH_KEY" | cut -d '"' -f4 | head -n1)

    # Fallback OS only
    if [ -z "$asset_url" ]; then
        asset_url=$(echo "$release_json" | grep browser_download_url | grep -i "$OS_KEY" | cut -d '"' -f4 | head -n1)
    fi

    if [ -z "$asset_url" ]; then
        echo -e "${RED}❌ No suitable asset found in release${NC}"
        exit 1
    fi

    binary_name=$(basename "$asset_url")
    binary_path="${downloads_dir}/${binary_name}"

    echo -e "${GREEN}✅ Found asset: ${binary_name}${NC}"
    echo -e "${CYAN}ℹ️ Downloading to ${downloads_dir}...${NC}"

    if ! curl -L -o "${binary_path}" "$asset_url"; then
        echo -e "${RED}❌ Download failed${NC}"
        exit 1
    fi

    file_size=$(stat -f%z "${binary_path}" 2>/dev/null || stat -c%s "${binary_path}" 2>/dev/null)
    echo -e "${CYAN}ℹ️ Downloaded file size: ${file_size} bytes${NC}"

    if [ "$file_size" -lt 1000 ]; then
        echo -e "${RED}❌ Downloaded file too small — likely error file${NC}"
        exit 1
    fi

    chmod +x "${binary_path}"

    echo -e "${GREEN}✅ Installation completed!${NC}"
    echo -e "${CYAN}ℹ️ Running program...${NC}"

    "${binary_path}"
}

main() {
    print_logo
    get_latest_version
    detect_os
    install_cursor_free_vip
}

main
