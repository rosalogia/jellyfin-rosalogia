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
