#!/bin/sh

set -eu

gitref=$(cut -d" " -f 3 -)
branch=$(echo "${gitref}" | cut -d/ -f3)

# update the hook!
git show "${branch}:scripts/hook-post-receive.sh" > hooks/post-receive

rm -rf "$HOME/homelab"
mkdir -p "$HOME/homelab"

echo "==> Deploy Running"
echo "    branch: ${branch}"

git --work-tree="$HOME/homelab" checkout -f "${branch}"

cd "$HOME/homelab"

./scripts/deploy.sh
