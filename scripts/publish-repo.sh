#!/usr/bin/env bash
# Build the "rosalogia" pacman repo from the freshly built packages and publish it as the
# assets of the "repo" GitHub release. Packages are signed when GPG_PRIVATE_KEY is set.
#
# Env: GH_TOKEN, GH_REPO, optional GPG_PRIVATE_KEY
set -euo pipefail

repo=rosalogia
tag=repo

rm -rf out
mkdir out
cp ./*/*.pkg.tar.zst out/
cp rosalogia.asc out/
cd out

sign=()
if [[ -n "${GPG_PRIVATE_KEY:-}" ]]; then
    gpg --batch --import <<< "$GPG_PRIVATE_KEY"
    for pkg in *.pkg.tar.zst; do
        gpg --batch --yes --detach-sign "$pkg"
    done
    sign=(--sign)
fi

repo-add "${sign[@]}" "$repo.db.tar.gz" ./*.pkg.tar.zst

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
