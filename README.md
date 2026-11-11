# jellyfin-arch

Arch Linux packages for the rosalogia Jellyfin fork
([server](https://github.com/rosalogia/jellyfin), [web](https://github.com/rosalogia/jellyfin-web)),
built from each fork's `fork-stable` branch: the latest upstream Jellyfin release with the fork's
features (video clips, Chinese study subtitles) applied on top.

- `jellyfin-server-rosalogia` replaces `jellyfin-server`
- `jellyfin-web-rosalogia` replaces `jellyfin-web`

Both keep the official package's paths, `jellyfin` user and `jellyfin.service`, so an existing
library in `/var/lib/jellyfin` carries over.

`LICENSE.arch-packaging` covers the files derived from the Arch Linux packaging
(PKGBUILD structure, `sysusers.conf`, `tmpfiles.conf`, `*.patch`).

## Installing

Add the repository to `/etc/pacman.conf`:

```ini
[rosalogia]
Server = https://github.com/rosalogia/jellyfin-arch/releases/download/repo
```

If the packages are signed, import and trust the signing key once:

```sh
sudo pacman-key --recv-keys <KEY_ID>   # or: sudo pacman-key --add rosalogia.asc
sudo pacman-key --lsign-key <KEY_ID>
```

If they aren't, add `SigLevel = Optional TrustAll` under `[rosalogia]`.

Then install. Pacman offers to remove the conflicting official packages:

```sh
aura -Sy jellyfin-server-rosalogia jellyfin-web-rosalogia
sudo systemctl restart jellyfin
```

Upgrades then come with the rest of the system (`aura -Syu`).

## How updates work

`.github/workflows/build.yml` runs daily. When upstream tags a new stable release it:

1. rebases each fork's `fork-stable` branch onto the new tag,
2. runs the server test suite and the web client typecheck,
3. pushes the rebased branches, and fast-forwards each fork's `master` to upstream,
4. updates the PKGBUILDs, builds both packages and republishes the pacman repository.

If a rebase conflicts or a check fails, it opens an issue and leaves the published packages alone.
Fix the conflict on `fork-stable` by hand (rebase onto the new tag and push), and the next run
picks it up. The workflow can also be run by hand from the Actions tab.

### Secrets

- `FORK_PUSH_TOKEN`: fine-grained token for `rosalogia/jellyfin` and `rosalogia/jellyfin-web`
  with Contents and Workflows read/write.
- `GPG_PRIVATE_KEY` (optional): ASCII-armored private key used to sign the packages and the
  repository database.
