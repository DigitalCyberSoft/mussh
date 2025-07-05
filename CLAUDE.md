# mussh - Multi-host SSH Command Utility

This document contains helpful information for working with the mussh codebase.

## Project Overview

Mussh is a shell script utility for running SSH commands on multiple hosts in parallel. The latest version is 1.1, which adds modern SSH features, bash completion, and several quality-of-life improvements.

## Common Commands

### Building the RPM

```bash
# Create build directory and copy files
mkdir -p ~/rpmbuild/{SOURCES,SPECS,BUILD,RPMS,SRPMS}
mkdir -p ~/mussh/build-tmp/mussh-1.1
cp ~/mussh/{BUGS,CHANGES,EXAMPLES,INSTALL,README,mussh,mussh.1,mussh.spec,mussh-completion.bash} ~/mussh/build-tmp/mussh-1.1/

# Create source tarball
cd ~/mussh/build-tmp && tar -czf ~/rpmbuild/SOURCES/mussh-1.1.tgz mussh-1.1

# Copy spec file
cp ~/mussh/mussh.spec ~/rpmbuild/SPECS/

# Build RPM
rpmbuild -ba ~/rpmbuild/SPECS/mussh.spec
```

### Testing

```bash
# Test basic functionality
mussh -h localhost -c "hostname"

# Test with multiple hosts
mussh -h host1 host2 -c "uptime"

# Test with a hostfile
mussh -H hostfile.txt -c "df -h"

# Test wildcard pattern support
mussh -h "server*" -c "hostname"

# Test netgroup support
mussh -h @netgroup -c "hostname"
```

## Code Organization

- `mussh`: Main script file
- `mussh.1`: Man page
- `mussh-completion.bash`: Bash completion script
- `mussh.spec`: RPM spec file
- `CHANGES`: Version history
- `EXAMPLES`: Example usage
- `INSTALL`: Installation instructions
- `README`: Project readme
- `BUGS`: Known issues

## Key Features Added in v1.1

- Jump host support using `-J` (requires OpenSSH 7.3+)
- Connection sharing with ControlMaster/ControlPath/ControlPersist
- Enhanced bash completion with Shift+Tab for adding all matching hosts
- Wildcard pattern support for host specifications (e.g., `-h server*`)
- Various modern SSH options for improved functionality
- Improved file locking mechanism
- Fixed dependency on `seq`

## Code Style Preferences

- Proper error handling with meaningful error messages
- Use `[[ ]]` instead of `[ ]` for conditionals when possible
- Consistent indentation with spaces
- Maintain backward compatibility with older systems
- Descriptive variable names (all uppercase for global variables)
- Use modern bash features but maintain POSIX compatibility where possible

## Integration Points

- Bash completion script is installed to `/etc/bash_completion.d/`
- Man page is installed to standard man location
- Main script is installed to `/usr/bin/`

## Codebase Peculiarities

- The script uses a temporary directory for managing parallel connections
- The bash completion uses Shift+Tab for adding all matching hosts
- The `-h` option supports wildcard patterns by searching through SSH configuration
- Netgroups can be specified with either `-n netgroup` or `-h @netgroup`