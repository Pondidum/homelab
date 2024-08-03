#!/bin/sh

set -eu

gitref=$(cut -d" " -f 3 -)
branch=$(echo "${gitref}" | cut -d/ -f3)

# update the hook!
git show "${branch}:scripts/hook-post-receive.sh" > hooks/post-receive
chmod +x hooks/post-receive

rm -rf "$HOME/homelab"
mkdir -p "$HOME/homelab"

git --work-tree="$HOME/homelab" checkout -f "${branch}"

cd "$HOME/homelab"


export RED="\033[0;31m"
export GREEN="\033[0;32m"
export YELLOW="\033[0;33m"
export BLUE="\033[0;34m"
export LIGHT_BLUE="\033[0;34m"
export COLOR_RESET="\033[0m"

echo "${BLUE}==> Running scripts/deploy.sh${COLOR_RESET}"

if ./scripts/deploy.sh; then
  echo "${GREEN}==> Done${COLOR_RESET}"
else
  echo "${RED}==> Failed${COLOR_RESET}"
fi
