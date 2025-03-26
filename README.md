# mussh - MUlti-host SSH Command Executor (Enhanced Fork)

[![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)

This is an enhanced fork of the original mussh utility created by Dave Fogarty. Mussh is a powerful shell script that allows you to execute commands on multiple hosts in parallel via SSH. Perfect for managing clusters, server farms, or any scenario where you need to run the same command across many machines.

## What's New in This Fork

This fork adds several modern features to the original mussh utility:

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

### From RPM (Fedora/RHEL/CentOS)

```bash
# Install from the RPM
sudo rpm -ivh mussh-1.1-1.noarch.rpm
```

### From Source

```bash
# Clone the repository
git clone https://github.com/DigitalCyberSoft/mussh.git
cd mussh

# Install manually
sudo cp mussh /usr/bin/
sudo cp mussh.1 /usr/share/man/man1/
sudo gzip /usr/share/man/man1/mussh.1
sudo cp mussh-completion.bash /etc/bash_completion.d/mussh

# Activate bash completion for current session
source /etc/bash_completion.d/mussh
```

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