#!/usr/bin/env bash
# Clone a fork and rebase its fork-stable branch onto the newest upstream Jellyfin release.
# Nothing is pushed here; push-fork.sh does that once the result has been tested.
#
# Usage: sync-fork.sh <repo> <dir>     e.g. sync-fork.sh jellyfin work/jellyfin
# Env:   FORK_PUSH_TOKEN  token with Contents + Workflows write on the fork
# Exits 2 if the rebase conflicts. Prints "rebased=true" to $GITHUB_OUTPUT after a rebase.
set -euo pipefail
trap 'echo "${BASH_SOURCE[0]}:$LINENO: \`$BASH_COMMAND\` failed" >&2' ERR

repo=$1
dir=$2

git clone --quiet --branch fork-stable \
    "https://x-access-token:${FORK_PUSH_TOKEN}@github.com/rosalogia/$repo.git" "$dir"
cd "$dir"
git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
git remote add upstream "https://github.com/jellyfin/$repo.git"
# --force: upstream occasionally re-tags a release (v10.11.1), leaving the fork's copy stale.
# Only the current release tag is ever pushed back to the fork.
git fetch --quiet --force upstream master --tags

# Stable releases only (v12.4, v12.4.1, ...), never release candidates.
latest=$(git tag --list 'v*' | grep -E '^v[0-9]+(\.[0-9]+)*$' | sort -V | tail -n 1)
current=$(git describe --tags --abbrev=0 --match 'v*' --exclude '*-rc*' fork-stable)

if [[ "$current" == "$latest" ]] || [[ "$(printf '%s\n' "$current" "$latest" | sort -V | tail -n 1)" == "$current" ]]; then
    echo "$repo: fork-stable is already on $current"
else
    echo "$repo: rebasing fork-stable from $current onto $latest"
    if ! git rebase --onto "$latest" "$current" fork-stable; then
        git rebase --abort
        echo "$repo: rebase onto $latest conflicts; fork-stable left on $current" >&2
        exit 2
    fi
    if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
        echo "rebased=true" >> "$GITHUB_OUTPUT"
    fi
fi

echo "$repo: fork-stable is $(git rev-parse --short=10 HEAD) ($(git describe --long --tags --match 'v*' --exclude '*-rc*'))"
