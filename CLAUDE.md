# mussh - Multi-host SSH Command Utility

This document contains helpful information for working with the mussh codebase, including systematic approaches for version management, git workflows, and RPM building.

## Project Overview

Mussh is a shell script utility for running SSH commands on multiple hosts in parallel. The current version includes performance optimizations and modern SSH features.

## Version Management Process

When creating a new version (1.X), multiple files need to be updated systematically to maintain consistency across the project.

### Files That Must Be Updated for Version Changes

1. **mussh script** - Line 4
   ```bash
   MUSSH_VERSION="1.X"
   ```

2. **mussh.spec** - Line 7
   ```bash
   Version:	1.X
   ```

3. **mussh.spec changelog** - Add new entry at top
   ```bash
   %changelog
   * DATE Digital Cyber Soft <apps@digitalcybersoft.com> 1.X-1
   - Description of changes in this version
   
   * [previous entries...]
   ```

4. **CHANGES file** - Add new version section at top
   ```bash
   v1.X
   YYYY-MM-DD
   	- Description of changes
   	- Bug fixes
   	- New features
   
   v[previous version]
   ```

5. **Source tarball name**
   ```bash
   mussh-1.X.tgz
   ```

6. **Build directory structure**
   ```bash
   ~/mussh/build-tmp/mussh-1.X/
   ```

7. **Spec file setup directive**
   ```bash
   %setup -n mussh-1.X
   ```

### Systematic Version Update Process

```bash
# Example for version 1.X (replace X with actual version number)

# 1. Update mussh script version
sed -i 's/MUSSH_VERSION="1\.[0-9]"/MUSSH_VERSION="1.X"/' mussh

# 2. Update spec file version
sed -i 's/Version:\s*1\.[0-9]/Version:\t1.X/' mussh.spec

# 3. Update spec file setup directive
sed -i 's/%setup -n mussh-1\.[0-9]/%setup -n mussh-1.X/' mussh.spec

# 4. Manually update CHANGES file (add new version section)
# 5. Manually update spec file changelog (add new entry)
```

## Git Repository Issues and Solutions

### Repository Structure Understanding

**Issue**: Working with multiple repository locations caused confusion
- Development directory: `/home/user/mussh/` 
- GitHub repository: `/home/user/mussh/mussh-github/`

**Key Learning**: Always work directly in the GitHub-connected directory (`mussh-github/`) to avoid file synchronization issues.

### Git Workflow Issues Encountered

#### Issue 1: Rebase Conflicts
**Problem**: Merge conflicts during rebase operations
```
interactive rebase in progress; onto 4d328e2
Unmerged paths:
	both added:      README.md
```

**Solution Process**:
1. Manually edit conflicted files to resolve differences
2. Stage resolved files: `git add <filename>`
3. Continue rebase: `git rebase --continue`

**Prevention**: Always `git fetch origin` before making major changes

#### Issue 2: Remote URL Authentication
**Problem**: SSH remote URLs failing in restricted environments

**Solution**: Switch to HTTPS for better compatibility
```bash
git remote set-url origin https://github.com/DigitalCyberSoft/mussh.git
```

#### Issue 3: Branch Divergence
**Problem**: Push rejected due to non-fast-forward changes
```
! [rejected]        main -> main (non-fast-forward)
```

**Solution**: Use safe force push after verifying changes
```bash
git push --force-with-lease origin main
```

**Why `--force-with-lease`**: Safer than `--force` because it verifies remote hasn't been updated by others

## RPM Build Issues and Solutions

### Critical RPM Build Requirements

For any version 1.X, these elements must be synchronized:

#### Issue 1: Directory Structure Mismatch
**Problem**: Spec file setup directive must match tarball directory name

**Requirement**: 
- Tarball contains: `mussh-1.X/`
- Spec file must have: `%setup -n mussh-1.X`

**Common Error**: Using `%setup -n mussh` when tarball is `mussh-1.X.tgz`

#### Issue 2: Build Section Organization
**Problem**: Directory creation in wrong RPM section

**Correct Structure**:
```bash
%prep
%setup -n mussh-1.X

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/usr/bin/
mkdir -p ${RPM_BUILD_ROOT}%{_mandir}/man1/
mkdir -p ${RPM_BUILD_ROOT}%{_sysconfdir}/bash_completion.d/
install mussh $RPM_BUILD_ROOT/usr/bin/
```

**Rule**: Build environment preparation goes in `%install`, not `%prep`

#### Issue 3: File Reference Consistency
**Problem**: Spec file references must match actual files

**Example**: If using `README.md`, spec file must reference `README.md`, not `README`
```bash
%doc INSTALL README.md BUGS CHANGES EXAMPLES
```

### RPM Build Process for Any Version 1.X

```bash
# Generic process for version 1.X

# 1. Create build directory
mkdir -p ~/mussh/build-tmp/mussh-1.X

# 2. Copy source files (adjust file list as needed)
cp {BUGS,CHANGES,EXAMPLES,INSTALL,README.md,mussh,mussh.1,mussh.spec,mussh-completion.bash,test} ~/mussh/build-tmp/mussh-1.X/
cp -r tests ~/mussh/build-tmp/mussh-1.X/

# 3. Create source tarball
cd ~/mussh/build-tmp && tar -czf ~/rpmbuild/SOURCES/mussh-1.X.tgz mussh-1.X

# 4. Copy spec file to build environment
cp ~/mussh/mussh-github/mussh.spec ~/rpmbuild/SPECS/

# 5. Build RPM
rpmbuild -ba ~/rpmbuild/SPECS/mussh.spec

# 6. Results will be in:
# ~/rpmbuild/RPMS/noarch/mussh-1.X-1.noarch.rpm
# ~/rpmbuild/SRPMS/mussh-1.X-1.src.rpm
```

## Version Update Checklist

Before releasing any version 1.X:

### Pre-Build Checklist
- [ ] Update `MUSSH_VERSION="1.X"` in mussh script
- [ ] Update `Version: 1.X` in mussh.spec
- [ ] Update `%setup -n mussh-1.X` in mussh.spec
- [ ] Add changelog entry in mussh.spec with correct date and version
- [ ] Add version section in CHANGES file
- [ ] Verify all file references in spec file match actual files
- [ ] Test script functionality with new version number

### Build Verification Checklist
- [ ] Source tarball created with correct name: `mussh-1.X.tgz`
- [ ] Tarball contains directory: `mussh-1.X/`
- [ ] RPM builds without errors
- [ ] RPM package information shows correct version
- [ ] RPM file list includes all expected files
- [ ] Installation test successful

### Git Workflow Checklist
- [ ] All changes committed to GitHub repository
- [ ] Version tag created: `git tag v1.X`
- [ ] Changes pushed to remote: `git push origin main --tags`
- [ ] No merge conflicts or rebase issues

## Future Development Guidelines

### Version Management
1. **Always update all version references simultaneously** to avoid inconsistencies
2. **Use search/replace carefully** to catch all version strings
3. **Test build process** before finalizing version changes
4. **Document changes** in both CHANGES file and spec changelog

### Git Best Practices
1. **Work in the GitHub directory** (`mussh-github/`) directly
2. **Fetch before major operations**: `git fetch origin`
3. **Use safe force push**: `git push --force-with-lease origin main`
4. **Tag releases**: `git tag v1.X && git push origin --tags`

### RPM Best Practices
1. **Maintain file synchronization** between spec file and actual source files
2. **Test build process** in clean environment
3. **Verify package contents** before distribution
4. **Keep build dependencies minimal** for broader compatibility

## Common Commands Reference

### Version Update Commands (Replace X with target version)
```bash
# Update version in script
sed -i 's/MUSSH_VERSION="1\.[0-9]"/MUSSH_VERSION="1.X"/' mussh

# Update version in spec
sed -i 's/Version:\s*1\.[0-9]/Version:\t1.X/' mussh.spec
sed -i 's/%setup -n mussh-1\.[0-9]/%setup -n mussh-1.X/' mussh.spec

# Build RPM
mkdir -p ~/mussh/build-tmp/mussh-1.X
cp [files] ~/mussh/build-tmp/mussh-1.X/
cd ~/mussh/build-tmp && tar -czf ~/rpmbuild/SOURCES/mussh-1.X.tgz mussh-1.X
rpmbuild -ba ~/rpmbuild/SPECS/mussh.spec
```

### Git Workflow Commands
```bash
# Safe git workflow
git fetch origin
git add .
git commit -m "Update to version 1.X with [description]"
git push --force-with-lease origin main
git tag v1.X
git push origin --tags
```

### Verification Commands
```bash
# Verify RPM package
rpm -qip ~/rpmbuild/RPMS/noarch/mussh-1.X-1.noarch.rpm
rpm -qlp ~/rpmbuild/RPMS/noarch/mussh-1.X-1.noarch.rpm

# Test installation
sudo rpm -Uvh ~/rpmbuild/RPMS/noarch/mussh-1.X-1.noarch.rpm
mussh -V  # Should show "Version: 1.X"
```

This systematic approach ensures consistency across all version updates and helps avoid the issues encountered during development.