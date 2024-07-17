#!/bin/sh

set -eu

rm -rf "$HOME/homelab"
mkdir -p "$HOME/homelab"

echo "==> Deploy Running"
gitref=$(cut -d" " -f 3 -)
branch=$(echo "${gitref}" | cut -d/ -f3)

echo "    branch: ${branch}"

git --work-tree="$HOME/homelab" checkout -f "${branch}"

cd "$HOME/homelab"

./scripts/deploy.sh
