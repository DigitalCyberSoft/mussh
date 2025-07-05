#
# mussh spec file
# $Id: mussh.spec,v 1.8 2006/12/26 22:27:51 doughnut Exp $
#
Summary:	MUltihost SSH
Name:		mussh
Version:	1.1
Release:	1
License:	GPL
BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)
Group:		Applications/System
Source:		%{name}-%{version}.tgz
URL:		http://www.sourceforge.net/projects/mussh
Packager:	Dave Fogarty <dave@collegenet.com>

%description
Mussh is a shell script that allows you to execute a command or script
over ssh on multiple hosts with one command. When possible mussh will use
ssh-agent and RSA/DSA keys to minimize the need to enter your password
more than once.

%prep
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/bin/
mkdir -p ${RPM_BUILD_ROOT}%{_mandir}/man1/
mkdir -p ${RPM_BUILD_ROOT}%{_sysconfdir}/bash_completion.d/
%setup -n mussh

%install
install mussh $RPM_BUILD_ROOT/usr/bin/
gzip mussh.1
install mussh.1.gz ${RPM_BUILD_ROOT}%{_mandir}/man1/
install -m 644 mussh-completion.bash ${RPM_BUILD_ROOT}%{_sysconfdir}/bash_completion.d/mussh

%files
%defattr(-, root, root)
%doc INSTALL README BUGS CHANGES EXAMPLES
/usr/bin/mussh
%{_mandir}/man1/*
%{_sysconfdir}/bash_completion.d/mussh

%changelog
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
