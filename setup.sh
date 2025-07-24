#!/usr/bin/env bash
#
# setup.sh - Installation script for mussh
#
# This script installs mussh globally on the system.
# It supports both Linux and macOS platforms.
#

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script information
SCRIPT_NAME="mussh"
SCRIPT_VERSION=$(grep "MUSSH_VERSION=" mussh | cut -d'"' -f2)

# Platform detection
case "$(uname -s)" in
    Darwin*)
        PLATFORM="macOS"
        BIN_DIR="/usr/local/bin"
        MAN_DIR="/usr/local/share/man/man1"
        COMPLETION_DIR="/usr/local/etc/bash_completion.d"
        ;;
    Linux*)
        PLATFORM="Linux"
        BIN_DIR="/usr/bin"
        MAN_DIR="/usr/share/man/man1"
        if [ -d "/etc/bash_completion.d" ]; then
            COMPLETION_DIR="/etc/bash_completion.d"
        else
            COMPLETION_DIR="/usr/share/bash-completion/completions"
        fi
        ;;
    *)
        PLATFORM="Unix"
        BIN_DIR="/usr/local/bin"
        MAN_DIR="/usr/local/share/man/man1"
        COMPLETION_DIR="/usr/local/etc/bash_completion.d"
        ;;
esac

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_info() {
    print_status "$BLUE" "ℹ  $1"
}

print_success() {
    print_status "$GREEN" "✓ $1"
}

print_warning() {
    print_status "$YELLOW" "⚠ $1"
}

print_error() {
    print_status "$RED" "✗ $1"
}

# Function to check if running as root
is_root() {
    [ "$(id -u)" -eq 0 ]
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install files with proper permissions
install_file() {
    local src=$1
    local dest=$2
    local mode=${3:-644}
    local description=$4
    
    if [ ! -f "$src" ]; then
        print_error "Source file $src not found"
        return 1
    fi
    
    print_info "Installing $description to $dest"
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"
    
    # Copy file and set permissions
    cp "$src" "$dest"
    chmod "$mode" "$dest"
    
    print_success "Installed $description"
}

# Function to run command with sudo if needed
run_with_sudo() {
    if is_root; then
        "$@"
    else
        sudo "$@"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check for required files
    local missing_files=()
    
    if [ ! -f "mussh" ]; then
        missing_files+=("mussh")
    fi
    
    if [ ! -f "mussh.1" ]; then
        missing_files+=("mussh.1")
    fi
    
    if [ ! -f "mussh-completion.bash" ]; then
        missing_files+=("mussh-completion.bash")
    fi
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_error "Missing required files: ${missing_files[*]}"
        print_error "Please run this script from the mussh source directory"
        exit 1
    fi
    
    # Check for sudo if not root
    if ! is_root && ! command_exists sudo; then
        print_error "This script requires root privileges or sudo"
        print_error "Please run as root or install sudo"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to install mussh
install_mussh() {
    print_info "Installing mussh $SCRIPT_VERSION on $PLATFORM..."
    
    # Check if we need sudo
    if ! is_root; then
        print_warning "Root privileges required for system installation"
        print_info "You will be prompted for your password..."
    fi
    
    # Install main script
    if ! run_with_sudo install_file "mussh" "$BIN_DIR/mussh" 755 "mussh executable"; then
        return 1
    fi
    
    # Install man page
    if ! run_with_sudo install_file "mussh.1" "$MAN_DIR/mussh.1" 644 "man page"; then
        print_warning "Failed to install man page (continuing anyway)"
    fi
    
    # Install bash completion
    if ! run_with_sudo install_file "mussh-completion.bash" "$COMPLETION_DIR/mussh" 644 "bash completion"; then
        print_warning "Failed to install bash completion (continuing anyway)"
    fi
    
    # Update man database if possible
    if command_exists mandb; then
        print_info "Updating man database..."
        run_with_sudo mandb -q 2>/dev/null || true
    elif command_exists makewhatis; then
        print_info "Updating man database..."
        run_with_sudo makewhatis "$MAN_DIR" 2>/dev/null || true
    fi
    
    print_success "Installation completed successfully!"
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    if [ -x "$BIN_DIR/mussh" ]; then
        local installed_version=$("$BIN_DIR/mussh" -V 2>/dev/null | grep -o '[0-9.]*' || echo "unknown")
        print_success "mussh $installed_version installed in $BIN_DIR"
    else
        print_error "mussh executable not found in $BIN_DIR"
        return 1
    fi
    
    if [ -f "$MAN_DIR/mussh.1" ]; then
        print_success "Man page installed in $MAN_DIR"
    else
        print_warning "Man page not found in $MAN_DIR"
    fi
    
    if [ -f "$COMPLETION_DIR/mussh" ]; then
        print_success "Bash completion installed in $COMPLETION_DIR"
    else
        print_warning "Bash completion not found in $COMPLETION_DIR"
    fi
}

# Function to show usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Install mussh globally on the system.

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version information
    --uninstall     Uninstall mussh from the system

EXAMPLES:
    $0                  # Install mussh
    $0 --uninstall      # Remove mussh

NOTES:
    - This script requires root privileges
    - On macOS, files are installed to /usr/local/
    - On Linux, files are installed to /usr/
    - Bash completion may require a new shell session to take effect

EOF
}

# Function to uninstall mussh
uninstall_mussh() {
    print_info "Uninstalling mussh..."
    
    if ! is_root; then
        print_warning "Root privileges required for uninstallation"
        print_info "You will be prompted for your password..."
    fi
    
    # Remove files
    local files_removed=0
    
    if [ -f "$BIN_DIR/mussh" ]; then
        run_with_sudo rm -f "$BIN_DIR/mussh"
        print_success "Removed $BIN_DIR/mussh"
        ((files_removed++))
    fi
    
    if [ -f "$MAN_DIR/mussh.1" ]; then
        run_with_sudo rm -f "$MAN_DIR/mussh.1"
        print_success "Removed $MAN_DIR/mussh.1"
        ((files_removed++))
    fi
    
    if [ -f "$COMPLETION_DIR/mussh" ]; then
        run_with_sudo rm -f "$COMPLETION_DIR/mussh"
        print_success "Removed $COMPLETION_DIR/mussh"
        ((files_removed++))
    fi
    
    if [ $files_removed -eq 0 ]; then
        print_warning "No mussh files found to remove"
    else
        print_success "Uninstallation completed ($files_removed files removed)"
    fi
}

# Main function
main() {
    # Parse command line arguments
    case "${1:-}" in
        -h|--help)
            show_usage
            exit 0
            ;;
        -v|--version)
            echo "mussh setup script"
            echo "mussh version: ${SCRIPT_VERSION:-unknown}"
            exit 0
            ;;
        --uninstall)
            check_prerequisites
            uninstall_mussh
            exit 0
            ;;
        "")
            # Install mode (default)
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
    
    # Show header
    echo
    print_info "mussh Installation Script"
    print_info "Platform: $PLATFORM"
    print_info "Version: ${SCRIPT_VERSION:-unknown}"
    echo
    
    # Run installation
    check_prerequisites
    install_mussh
    verify_installation
    
    echo
    print_success "mussh has been installed successfully!"
    print_info "You can now use 'mussh --help' to get started"
    
    # Platform-specific notes
    if [ "$PLATFORM" = "macOS" ]; then
        print_info "Note: On macOS, you may need to start a new terminal session"
        print_info "      for bash completion to take effect"
    fi
    
    echo
}

# Run main function with all arguments
main "$@"