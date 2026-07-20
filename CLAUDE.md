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
- `VERSION`: plain version string (e.g. `1.2.5`)
- `mussh.rb`: post-release only -- after the tag is pushed, update `url` to the new tag archive and recompute `sha256`

## Building

Commit the version bumps, tag the release commit, then build from `git archive` of the tag -- never from the working tree (the 1.2.4 artifacts were built from an uncommitted tree and did not match the tag).

```bash
# Stage sources from the tag
rm -rf ~/mussh/build-tmp
mkdir -p ~/mussh/build-tmp/src ~/mussh/build-tmp/mussh-1.X
git -C ~/mussh archive v1.X | tar -x -C ~/mussh/build-tmp/src
cd ~/mussh/build-tmp/src
cp BUGS CHANGES EXAMPLES INSTALL LICENSE README.md mussh mussh.1 mussh.spec mussh-completion.bash test ../mussh-1.X/
cp -r tests ../mussh-1.X/

# RPM
cd ~/mussh/build-tmp && tar -czf ~/rpmbuild/SOURCES/mussh-1.X.tgz mussh-1.X
cp src/mussh.spec ~/rpmbuild/SPECS/
rpmbuild -ba ~/rpmbuild/SPECS/mussh.spec

# DEB (from RPM via alien)
cd ~/rpmbuild/RPMS/noarch
fakeroot alien --to-deb mussh-1.X-1.noarch.rpm
```

The tarball directory name must match `%setup -n` in the spec file, and `%doc` entries must match actual filenames.

## Git

Remote is HTTPS: `https://github.com/DigitalCyberSoft/mussh.git`

The only branch is `main`, local and remote (`master` no longer exists).

```bash
git push origin main
git tag v1.X && git push origin v1.X   # push the one tag; --tags would push every local tag
```

## Build Artifacts (not tracked)

`build-tmp/`, `dist/`, `*.tar.gz`, `*.rpm`, `*.deb` -- see `.gitignore`.
