#!/usr/bin/env bash
# Point each PKGBUILD at its fork's current fork-stable commit.
#
# Usage: update-pkgbuilds.sh <work dir>     (the directory sync-fork.sh cloned into)
# Prints "changed=true|false" to $GITHUB_OUTPUT when set.
set -euo pipefail
trap 'echo "${BASH_SOURCE[0]}:$LINENO: \`$BASH_COMMAND\` failed" >&2' ERR

work=$1
changed=false

update() {
    local pkgbuild=$1 checkout=$2
    local commit version
    commit=$(git -C "$checkout" rev-parse --short=10 fork-stable)
    version=$(git -C "$checkout" describe --long --tags --match 'v*' --exclude '*-rc*' fork-stable | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g')

    if ! grep -qx "_commit=$commit" "$pkgbuild"; then
        sed -i "s/^_commit=.*/_commit=$commit/; s/^pkgver=.*/pkgver=$version/; s/^pkgrel=.*/pkgrel=1/" "$pkgbuild"
        echo "$pkgbuild -> $version"
        changed=true
    fi
}

update jellyfin-server-rosalogia/PKGBUILD "$work/jellyfin"
update jellyfin-web-rosalogia/PKGBUILD "$work/jellyfin-web"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "changed=$changed" >> "$GITHUB_OUTPUT"
fi
