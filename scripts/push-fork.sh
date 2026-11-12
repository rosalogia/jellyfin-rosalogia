#!/usr/bin/env bash
# Push a fork's (possibly rebased) fork-stable branch and its base release tag, and
# fast-forward the fork's master to upstream master.
#
# Usage: push-fork.sh <dir>     e.g. push-fork.sh work/jellyfin
set -euo pipefail
trap 'echo "${BASH_SOURCE[0]}:$LINENO: \`$BASH_COMMAND\` failed" >&2' ERR

cd "$1"

base=$(git describe --tags --abbrev=0 --match 'v*' --exclude '*-rc*' fork-stable)
remote_head=$(git rev-parse origin/fork-stable)

if [[ "$(git rev-parse fork-stable)" != "$remote_head" ]]; then
    # Only overwrite the branch if nobody pushed to it since we cloned.
    git push --force-with-lease="fork-stable:$remote_head" origin fork-stable "refs/tags/$base"
fi

# master is a plain mirror of upstream; a fast-forward push fails loudly if it ever diverges.
git push origin refs/remotes/upstream/master:refs/heads/master
