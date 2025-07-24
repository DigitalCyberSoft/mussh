# mussh - MUlti-host SSH Command Executor (Enhanced Fork)

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

> **This is an enhanced fork of the original mussh utility from [SourceForge](https://sourceforge.net/projects/mussh/) created by Dave Fogarty.**

Mussh is a powerful shell script that allows you to execute commands on multiple hosts in parallel via SSH. Perfect for managing clusters, server farms, or any scenario where you need to run the same command across many machines.

## What's New in This Fork

This fork adds several modern features to the original mussh utility:

- **Implicit arguments**: `mussh host1 host2 "command"` - no need for `-h` or `-c` flags
- **zsh compatibility**: Full support for zsh shell with automatic bash emulation
- **macOS support**: Native compatibility with macOS and Homebrew installation
- **Easy installation**: Automated setup script with sudo handling
- Support for SSH jump hosts via `-J` option (OpenSSH 7.3+)
- Connection sharing with SSH ControlMaster/ControlPath/ControlPersist
- Wildcard pattern matching for host selection (`mussh -h "server*"`)
- Enhanced bash completion with Shift+Tab for adding all matching hosts
- Support for modern SSH options (logging, binding, forwarding)
- Fixed bugs from v1.0 and improved script reliability
- Modern bash script practices and better error handling
- **Performance optimizations**: 97-99% faster core operations by replacing external commands with bash internals

## Performance Improvements

The latest version includes significant performance optimizations:

- **File operations**: Replaced `cat` with bash redirection (`$(<file)`) - 97% faster
- **Word counting**: Replaced `wc -w` with parameter expansion - 99% faster  
- **Line reading**: Replaced `head -n 1` with bash `read` - 99% faster
- **PID handling**: Optimized concurrent process management
- **Overall**: Dramatically reduced subprocess overhead and improved execution speed

## Features

- Execute commands on multiple remote hosts in parallel
- Support for SSH agent and key authentication
- Concurrent execution with configurable parallelism
- SSH jump host support via ProxyJump
- Connection sharing with SSH ControlMaster
- Comprehensive Bash completion with smart host discovery
- Support for netgroups
- Works on all UNIX-like systems with standard tools
- Comprehensive test suite for validation

## Installation

### One-Line Install (Recommended)

```bash
# Install or update to latest version
curl -fsSL https://raw.githubusercontent.com/DigitalCyberSoft/mussh/main/install.sh | bash

# Uninstall completely
curl -fsSL https://raw.githubusercontent.com/DigitalCyberSoft/mussh/main/install.sh | bash -s -- --uninstall
```

**Features of the one-line installer:**
- ✅ **Smart installation**: Automatically detects if update is needed
- ✅ **User vs system install**: Works with or without sudo
- ✅ **Platform detection**: Supports Linux and macOS
- ✅ **PATH management**: Automatically adds ~/.local/bin to PATH for user installs
- ✅ **Clean uninstall**: Removes all files completely
- ✅ **No dependencies**: Only requires curl and bash

### Alternative: Setup Script

```bash
# Clone the repository
git clone https://github.com/DigitalCyberSoft/mussh.git
cd mussh

# Run the automated installer
./setup.sh
```

### Homebrew (macOS)

```bash
# Install via Homebrew (using the included formula)
brew install --build-from-source mussh.rb

# Or tap and install from a custom repository
# (if published to a tap in the future)
```

### Package Managers

#### RPM (Fedora/RHEL/CentOS)
```bash
# Install from the RPM
sudo rpm -ivh mussh-1.2.1-1.noarch.rpm
```

#### DEB (Debian/Ubuntu)
```bash
# Install from the DEB package
sudo dpkg -i mussh_1.2.1-2_all.deb
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/DigitalCyberSoft/mussh.git
cd mussh

# Linux installation
sudo cp mussh /usr/bin/
sudo cp mussh.1 /usr/share/man/man1/
sudo cp mussh-completion.bash /etc/bash_completion.d/mussh

# macOS installation
sudo cp mussh /usr/local/bin/
sudo cp mussh.1 /usr/local/share/man/man1/
sudo cp mussh-completion.bash /usr/local/etc/bash_completion.d/mussh

# Make executable
sudo chmod +x /usr/bin/mussh  # or /usr/local/bin/mussh on macOS
```

### Shell Compatibility

mussh works with both bash and zsh:
- **bash**: Native support
- **zsh**: Automatic bash compatibility mode enabled

## Quick Start

### Basic Usage

```bash
# Run a command on multiple hosts
mussh -h server1 server2 server3 -c "uptime"

# Run a command on hosts matching a pattern
mussh -h "app-server*" -c "systemctl status nginx"

# Use a file containing a list of hosts
mussh -H hostlist.txt -c "df -h"

# Run a script on multiple hosts
mussh -h server1 server2 -C script.sh

# Use a jump host to access internal servers
mussh -J bastion.example.com -h internal-server1 internal-server2 -c "hostname"
```

### Advanced Usage

```bash
# Run commands in parallel on 5 hosts at a time
mussh -m 5 -h host1 host2 host3 host4 host5 host6 host7 -c "yum update -y"

# Use SSH connection multiplexing for better performance
mussh -CM -CP 10m -h host1 host2 host3 -c "tail -f /var/log/syslog"

# Run multiple commands
mussh -h webservers -c "systemctl restart nginx; systemctl status nginx"

# Specify a different user for each host
mussh -h user1@host1 user2@host2 -c "whoami"

# Use a default login for all hosts
mussh -l admin -h host1 host2 -c "whoami"

# Expand hosts from netgroups
mussh -h @webservers -c "systemctl restart apache2"
```

## Testing

The project includes a comprehensive test suite to validate functionality and performance:

```bash
# Run quick tests
./test quick

# Run full test suite
./test full

# Run performance benchmarks
./test performance

# Run individual test suites
cd tests
./function_tests.sh           # Function-level performance tests
./quick_performance_test.sh   # Basic performance validation
./test_mussh.sh              # Comprehensive functionality tests
./performance_test.sh        # Extended benchmarks
```

## Tab Completion

Mussh includes a powerful Bash completion script that makes it easy to work with multiple hosts:

- Press Tab to complete available hosts from SSH config and known_hosts
- Press Shift+Tab to add all matching hosts at once
- Hosts already selected are filtered out from completion options

## Options

### Host Selection
- `-h [user@]host [host...]`: Add hosts to the execution list (supports wildcards)
- `-H hostfile [hostfile...]`: Add hosts from files (one host per line)
- `-n netgroup`: Add hosts from a netgroup
- `-l login`: Use this login when none is specified with hostname
- `-L login`: Force this login name for all hosts

### SSH Options
- `-i identity [identity...]`: Load identity files
- `-o ssh-option`: Pass option to SSH with -o
- `-J [user@]host`: Use a jump host (ProxyJump)
- `-CM`: Enable SSH ControlMaster for connection sharing
- `-CP time`: Keep master connection open in background
- `-S path`: Location of ControlPath socket
- `-T socket`: UNIX-domain socket for authentication agent
- `-HKH`: Enable HashKnownHosts for better security
- `-VHD`: Enable verification of host keys via DNS

### Execution Control
- `-c command`: Add a command to execute on each host
- `-C scriptfile [scriptfile...]`: Add file contents as commands
- `-m [n]`: Run concurrently on n hosts at a time (default: 1)
- `-b`: Block output per host (don't mingle output)
- `-B`: Allow output mingling (default)
- `-t secs`: Set SSH timeout
- `-d [n]`: Set debug level (0-2)
- `-v [n]`: Set SSH verbosity level (0-3)
- `-q`: Quiet mode

## Building from Source

```bash
# Set up RPM build environment
mkdir -p ~/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}

# Create source tarball
mkdir -p /tmp/mussh-1.1
cp {BUGS,CHANGES,EXAMPLES,INSTALL,README,mussh,mussh.1,mussh.spec,mussh-completion.bash} /tmp/mussh-1.1/
cd /tmp && tar -czf ~/rpmbuild/SOURCES/mussh-1.1.tgz mussh-1.1

# Build RPM
cp mussh.spec ~/rpmbuild/SPECS/
rpmbuild -ba ~/rpmbuild/SPECS/mussh.spec
```

## License

This project is licensed under the GPL v2 License, the same as the original project.

## Acknowledgments

* Original author: Dave Fogarty (https://sourceforge.net/projects/mussh/)
* Original contributors:
  * Jacob Lundberg (efficiency improvements)
  * Scott Bigelow (netgroup support)
  * Stephane Alnet (debug mode fixes)
* This fork by: Digital Cyber Soft

## Version History

See the [CHANGES](CHANGES) file for a detailed version history.