#!/usr/bin/env bash
# Build the "rosalogia" pacman repo from the freshly built packages and publish it as the
# assets of the "repo" GitHub release, signing the packages and the database.
#
# Env: GH_TOKEN, GH_REPO, GPG_PRIVATE_KEY
set -euo pipefail
trap 'echo "${BASH_SOURCE[0]}:$LINENO: \`$BASH_COMMAND\` failed" >&2' ERR

repo=rosalogia
tag=repo

rm -rf out
mkdir out
cp ./*/*.pkg.tar.zst out/
cp rosalogia.asc out/
cd out

if [[ -z "${GPG_PRIVATE_KEY:-}" ]]; then
    echo 'GPG_PRIVATE_KEY is not set; refusing to publish unsigned packages' >&2
    exit 1
fi
gpg --batch --import <<< "$GPG_PRIVATE_KEY"
for pkg in *.pkg.tar.zst; do
    gpg --batch --yes --detach-sign "$pkg"
done

repo-add --sign "$repo.db.tar.gz" ./*.pkg.tar.zst

# repo-add makes $repo.db and $repo.files symlinks, which release assets can't be.
for f in "$repo.db" "$repo.files"; do
    rm -f "$f" "$f.sig"
    cp "$f.tar.gz" "$f"
    if [[ -e "$f.tar.gz.sig" ]]; then
        cp "$f.tar.gz.sig" "$f.sig"
    fi
done

if ! gh release view "$tag" > /dev/null 2>&1; then
    gh release create "$tag" --title 'Pacman repository' --latest=false \
        --notes 'Packages for the rosalogia Jellyfin fork. See the README for how to add this repository to pacman.'
fi

# Upload first, then drop assets from older builds, so the repo is never empty.
gh release upload "$tag" --clobber ./*
gh release view "$tag" --json assets --jq '.assets[].name' | while read -r asset; do
    if [[ ! -e "$asset" ]]; then
        gh release delete-asset "$tag" "$asset" --yes
    fi
done
