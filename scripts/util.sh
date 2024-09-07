#!/bin/sh

log() {
  echo "${LIGHT_BLUE}${1}${COLOR_RESET}" >&2
}

export RED="\033[0;31m"
export GREEN="\033[0;32m"
export YELLOW="\033[0;33m"
export BLUE="\033[0;34m"
export LIGHT_BLUE="\033[0;34m"
export COLOR_RESET="\033[0m"