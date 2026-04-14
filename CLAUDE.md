# mussh

## Release Rules

- Never mention AI tools in commits, release notes, changelogs, or docs.

## Version Bumps

Update ALL of these together:

- `mussh` line 4: `MUSSH_VERSION="1.X"`
- `mussh.spec` line 7: `Version: 1.X`
- `mussh.spec` setup: `%setup -n mussh-1.X`
- `mussh.spec` changelog: add entry at top
- `CHANGES`: add version section at top

## Building

```bash
# RPM
mkdir -p ~/mussh/build-tmp/mussh-1.X
cp {BUGS,CHANGES,EXAMPLES,INSTALL,README.md,mussh,mussh.1,mussh.spec,mussh-completion.bash,test} ~/mussh/build-tmp/mussh-1.X/
cp -r tests ~/mussh/build-tmp/mussh-1.X/
cd ~/mussh/build-tmp && tar -czf ~/rpmbuild/SOURCES/mussh-1.X.tgz mussh-1.X
cp ~/mussh/mussh.spec ~/rpmbuild/SPECS/
rpmbuild -ba ~/rpmbuild/SPECS/mussh.spec

# DEB (from RPM via alien)
cd ~/rpmbuild/RPMS/noarch
fakeroot alien --to-deb mussh-1.X-1.noarch.rpm
```

The tarball directory name must match `%setup -n` in the spec file, and `%doc` entries must match actual filenames.

## Git

Remote is HTTPS: `https://github.com/DigitalCyberSoft/mussh.git`

Local branch is `master`, remote default is `main`. Both exist on the remote.

```bash
git push origin master
git tag v1.X && git push origin --tags
```

## Build Artifacts (not tracked)

`build-tmp/`, `dist/`, `*.tar.gz`, `*.rpm`, `*.deb` -- see `.gitignore`.
