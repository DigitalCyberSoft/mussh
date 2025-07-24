#
# mussh spec file
# $Id: mussh.spec,v 1.8 2006/12/26 22:27:51 doughnut Exp $
#
Summary:	MUltihost SSH
Name:		mussh
Version:	1.2.4
Release:	1
License:	GPL
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Group:		Applications/System
Source:		%{name}-%{version}.tgz
URL:		https://github.com/DigitalCyberSoft/mussh
Packager:	Digital Cyber Soft <apps@digitalcybersoft.com>

%description
Mussh is a shell script that allows you to execute a command or script
over ssh on multiple hosts with one command. When possible mussh will use
ssh-agent and RSA/DSA keys to minimize the need to enter your password
more than once.

This is an enhanced fork of the original mussh utility from SourceForge
(https://sourceforge.net/projects/mussh/) created by Dave Fogarty.

%prep
%setup -n mussh-1.2.4

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/bin/
mkdir -p ${RPM_BUILD_ROOT}%{_mandir}/man1/
mkdir -p ${RPM_BUILD_ROOT}%{_sysconfdir}/bash_completion.d/
install mussh $RPM_BUILD_ROOT/usr/bin/
gzip mussh.1
install mussh.1.gz ${RPM_BUILD_ROOT}%{_mandir}/man1/
install -m 644 mussh-completion.bash ${RPM_BUILD_ROOT}%{_sysconfdir}/bash_completion.d/mussh

%files
%defattr(-, root, root)
%doc INSTALL README.md BUGS CHANGES EXAMPLES
/usr/bin/mussh
%{_mandir}/man1/*
%{_sysconfdir}/bash_completion.d/mussh

%changelog
* Thu Jul 24 2025 Digital Cyber Soft <apps@digitalcybersoft.com> 1.2.4-1
- Enhanced argument parsing to support quoted single-word commands
- Fixed issue where single-word commands like "pwd" required spaces to be recognized
- Improved command detection logic for better user experience with quoted commands

* Sun Jul 06 2025 Digital Cyber Soft <apps@digitalcybersoft.com> 1.2.3-1
- Added --screen option to launch SSH connections in screen sessions
- Each host gets its own named window within a single screen session
- Implemented screen session management with automatic creation
- Added screen mode support in ssh_connect() function
- Added test script for screen functionality
- Updated help documentation for screen feature

* Sat Jul 06 2025 Digital Cyber Soft <apps@digitalcybersoft.com> 1.2.2-1
- Added zsh shell compatibility with automatic bash emulation
- Added macOS platform support with proper path detection
- Created automated setup.sh installer with sudo handling
- Added Homebrew formula for macOS users
- Added comprehensive shell compatibility test suite
- Updated documentation with multiple installation methods
- Fixed bug reporting URL to point to GitHub issues

* Sat Jul 05 2025 Digital Cyber Soft <apps@digitalcybersoft.com> 1.2.1-1
- Added implicit host arguments support (mussh host1 host2 -c "command")
- Added implicit command arguments support (mussh host1 host2 "command")
- Added safety checks to prevent mixing implicit and explicit arguments
- Updated documentation and help text with new usage examples
- Added comprehensive test suite for new implicit argument features

* Wed Mar 26 2025 Digital Cyber Soft <apps@digitalcybersoft.com> 1.2-1
- Performance optimizations: 97-99% faster core operations
- Replaced external commands with bash internals (cat, wc, head, tail)
- Optimized PID file handling for concurrent execution
- Added comprehensive test suite with performance validation
- Dramatically reduced subprocess overhead and improved execution speed

* Wed Mar 26 2025 Digital Cyber Soft <apps@digitalcybersoft.com> 1.1-1
- Upgrade to version 1.1
- Added modern SSH options (ControlMaster, -J, -E, HashKnownHosts, etc.)
- Added bash completion script with enhanced host discovery
- Incorporated all fixes from v1.0
- Fixed deprecated egrep with grep -E
- Improved file locking mechanism
- Added better error handling and safety features
- Enhanced parallel host processing

* Tue Dec 26 2006 Dave Fogarty <doughnut@doughnut.net> 0.7-1
- Added ssh timeout option

* Thu Aug 23 2005 Dave Fogarty <dave@collegenet.com>
- Added manpage

* Thu Aug 11 2005 Dave Fogarty <dave@collegenet.com>
- Re-package for 0.6-1BETA
- Async mode added

* Tue Jul 30 2002 Dave Fogarty <dave@collegenet.com>
- Re-package for 0.5
