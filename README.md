# mussh - MUlti-host SSH

Fork of [mussh](https://sourceforge.net/projects/mussh/) by Dave Fogarty.

Run commands on multiple hosts over SSH, in parallel.

## What this fork adds

- Implicit arguments: `mussh host1 host2 "uptime"` (no `-h`/`-c` needed)
- `--screen` mode: SSH sessions in GNU screen, one window per host
- `-J` jump host support (ProxyJump)
- ControlMaster/ControlPath/ControlPersist connection sharing
- Wildcard host patterns (`mussh -h "server*"`)
- Bash completion with host discovery from known_hosts/ssh config
- zsh and macOS compatibility
- Input validation for hostnames, SSH options, commands
- Replaced external commands (cat, wc, head) with bash builtins

## Install

```bash
# setup script
git clone https://github.com/DigitalCyberSoft/mussh.git
cd mussh && ./setup.sh

# or manually
sudo cp mussh /usr/bin/
sudo cp mussh.1 /usr/share/man/man1/
sudo cp mussh-completion.bash /etc/bash_completion.d/mussh

# macOS (Homebrew)
brew install --build-from-source mussh.rb

# RPM
sudo rpm -ivh mussh-1.2.4-1.noarch.rpm

# DEB
sudo dpkg -i mussh_1.2.4-2_all.deb
```

## Usage

```bash
# basic
mussh -h server1 server2 -c "uptime"

# implicit (no flags)
mussh server1 server2 "df -h"

# from a host file
mussh -H hostlist.txt -c "systemctl status nginx"

# run a script
mussh -h server1 server2 -C deploy.sh

# parallel (5 at a time)
mussh -m5 -H hostlist.txt -c "yum update -y"

# jump host
mussh -J bastion.example.com -h internal1 internal2 -c "hostname"

# screen mode
mussh --screen -h web1 web2 web3 -c "tail -f /var/log/syslog"
# then: screen -r mussh-session

# wildcard hosts (from known_hosts/ssh config)
mussh -h "app-*" -c "free -m"

# connection multiplexing
mussh -CM -CP 10m -h host1 host2 host3 -c "ps aux"
```

## Options

```
Host selection:
  -h [user@]host [host...]   Hosts to run on (supports wildcards)
  -H file [file...]          Read hosts from file
  -n netgroup                Hosts from netgroup
  -l login                   Default login name
  -L login                   Force login name for all hosts

Commands:
  -c "command"               Command to run
  -C scriptfile              Script file to run
  --screen                   Run in GNU screen session

Execution:
  -m [n]                     Concurrent hosts (0 = all, default: 1)
  -b                         Block output per host
  -t secs                    SSH connect timeout
  -s shell                   Remote shell (default: bash)

SSH:
  -i identity                Identity file for ssh-agent
  -o option                  SSH -o option
  -J [user@]host             Jump host (ProxyJump)
  -CM                        Enable ControlMaster
  -CP time                   ControlPersist duration
  -S path                    ControlPath socket
  -P                         Skip hosts where key auth fails

Security:
  --security-strict          Reject dangerous input (default)
  --security-normal          Warn about dangerous input
  --force-unsafe             Disable input validation

Debug:
  -d [0-2]                   Debug level
  -v [0-3]                   SSH verbosity
  -q                         Quiet mode
  -V                         Print version
```

## Building packages

See [CLAUDE.md](CLAUDE.md) for RPM/DEB build instructions.

## License

GPL v2 (same as original).

## Credits

- Original: Dave Fogarty
- Contributors: Jacob Lundberg, Scott Bigelow, Stephane Alnet
- This fork: Digital Cyber Soft
