#!/bin/sh

set -eu

. ./scripts/util.sh

main() {
  template_path="/var/lib/vz/template/cache"

  machine_config="${1:-""}"
  if [ -z "${machine_config}" ]; then
    log "--> no machine config specified"
    exit 1
  fi

  . "${machine_config}/options"

  log "==> Running ${hostname}"

  if ! [ -f "${template_path}/${template}.tar.xz" ]; then
    ./scripts/build-machine.sh "${template}"
  fi

  ./scripts/create-lxc.sh "${machine_config}"
}

main "$@"
