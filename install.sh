#!/usr/bin/env bash
#
# mussh - One-line installer/updater/uninstaller
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/DigitalCyberSoft/mussh/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/DigitalCyberSoft/mussh/main/install.sh | bash -s -- --uninstall

set -euo pipefail

MUSSH_VERSION="1.2.3"
GITHUB_REPO="DigitalCyberSoft/mussh"
BASE_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Platform detection
detect_platform() {
    case "$(uname -s)" in
        Linux*)     PLATFORM="linux" ;;
        Darwin*)    PLATFORM="macos" ;;
        *)          PLATFORM="unknown" ;;
    esac
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}Warning: Running as root. Installing system-wide.${NC}"
        INSTALL_DIR="/usr/bin"
        MAN_DIR="/usr/share/man/man1"
        COMPLETION_DIR="/etc/bash_completion.d"
    else
        # User installation
        INSTALL_DIR="$HOME/.local/bin"
        MAN_DIR="$HOME/.local/share/man/man1"
        COMPLETION_DIR="$HOME/.local/share/bash-completion/completions"
        
        # Create directories if they don't exist
        mkdir -p "$INSTALL_DIR" "$MAN_DIR" "$COMPLETION_DIR"
        
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo -e "${YELLOW}Adding $HOME/.local/bin to PATH in ~/.bashrc${NC}"
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
        fi
    fi
}

# Download and install files
install_mussh() {
    echo -e "${BLUE}Installing mussh v${MUSSH_VERSION}...${NC}"
    
    # Download main script
    echo "Downloading mussh script..."
    curl -fsSL "${BASE_URL}/mussh" -o "${INSTALL_DIR}/mussh"
    chmod +x "${INSTALL_DIR}/mussh"
    
    # Download man page
    echo "Installing man page..."
    curl -fsSL "${BASE_URL}/mussh.1" -o "${MAN_DIR}/mussh.1"
    
    # Download bash completion
    echo "Installing bash completion..."
    curl -fsSL "${BASE_URL}/mussh-completion.bash" -o "${COMPLETION_DIR}/mussh"
    
    echo -e "${GREEN}✓ mussh v${MUSSH_VERSION} installed successfully!${NC}"
    echo -e "${BLUE}Location: ${INSTALL_DIR}/mussh${NC}"
    
    # Test installation
    if command -v mussh >/dev/null 2>&1; then
        echo -e "${GREEN}✓ mussh is ready to use${NC}"
        mussh -V
    else
        echo -e "${YELLOW}⚠ mussh installed but not in PATH. Restart your shell or run:${NC}"
        echo -e "${BLUE}export PATH=\"${INSTALL_DIR}:\$PATH\"${NC}"
    fi
}

# Check for updates and install/update as needed
install_or_update_mussh() {
    # Get latest version from GitHub
    echo -e "${BLUE}Checking for latest version...${NC}"
    LATEST_VERSION=$(curl -fsSL "${BASE_URL}/VERSION" 2>/dev/null || echo "$MUSSH_VERSION")
    
    # Check if mussh is installed
    if command -v mussh >/dev/null 2>&1; then
        CURRENT_VERSION=$(mussh -V 2>/dev/null | grep -o 'Version: [0-9.]*' | cut -d' ' -f2 || echo "unknown")
        echo "Current version: $CURRENT_VERSION"
        echo "Latest version: $LATEST_VERSION"
        
        if [[ "$CURRENT_VERSION" == "$LATEST_VERSION" ]]; then
            echo -e "${GREEN}✓ Already up to date!${NC}"
            return
        fi
        
        echo -e "${BLUE}Updating mussh from v${CURRENT_VERSION} to v${LATEST_VERSION}...${NC}"
    else
        echo -e "${BLUE}Installing mussh v${LATEST_VERSION}...${NC}"
    fi
    
    # Use latest version for installation
    MUSSH_VERSION="$LATEST_VERSION"
    install_mussh
}

# Uninstall mussh
uninstall_mussh() {
    echo -e "${BLUE}Uninstalling mussh...${NC}"
    
    # Remove files
    REMOVED=0
    
    for dir in "/usr/bin" "$HOME/.local/bin"; do
        if [[ -f "$dir/mussh" ]]; then
            rm -f "$dir/mussh"
            echo "Removed $dir/mussh"
            ((REMOVED++))
        fi
    done
    
    for dir in "/usr/share/man/man1" "$HOME/.local/share/man/man1"; do
        if [[ -f "$dir/mussh.1" ]]; then
            rm -f "$dir/mussh.1"
            echo "Removed $dir/mussh.1"
        fi
    done
    
    for dir in "/etc/bash_completion.d" "$HOME/.local/share/bash-completion/completions"; do
        if [[ -f "$dir/mussh" ]]; then
            rm -f "$dir/mussh"
            echo "Removed $dir/mussh"
        fi
    done
    
    if [[ $REMOVED -gt 0 ]]; then
        echo -e "${GREEN}✓ mussh uninstalled successfully${NC}"
    else
        echo -e "${YELLOW}⚠ mussh was not found${NC}"
    fi
}

# Show usage
show_usage() {
    echo "mussh installer/uninstaller"
    echo ""
    echo "Usage:"
    echo "  Install/Update:  curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/install.sh | bash"
    echo "  Uninstall:       curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/main/install.sh | bash -s -- --uninstall"
    echo ""
    echo "Options:"
    echo "  --help      Show this help"
    echo "  --uninstall Remove mussh completely"
    echo ""
    echo "The script automatically detects if mussh is installed and updates to the latest version if needed."
}

# Main logic
main() {
    detect_platform
    
    case "${1:-install}" in
        --help|-h)
            show_usage
            ;;
        --uninstall|--remove|-r)
            uninstall_mussh
            ;;
        install|"")
            check_root
            install_or_update_mussh
            ;;
        *)
            echo -e "${RED}Error: Unknown option '$1'${NC}"
            show_usage
            exit 1
            ;;
    esac
}

main "$@"