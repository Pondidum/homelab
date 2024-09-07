#!/bin/sh

set -eu

. ./scripts/util.sh

machine_config="${1:-""}"
if [ -z "${machine_config}" ]; then
  log "--> no machine config specified"
  exit 1
fi

. "${machine_config}/options"


log "==> Migrating ${hostname}"

if ! pct list | grep "${hostname}\s" > /dev/null; then
  log "--> Unable to find machine"
  exit 0
fi

old_vmid=$(pct list | grep "${hostname}" | cut -d' ' -f 1)

log "    Current Machine ID: ${old_vmid}"

# rename old machine
# shutdown old machine
pct set "${old_vmid}" --hostname "${hostname}old"

if pct status "${old_vmid}" | grep "running"; then
  pct shutdown "${old_vmid}"
fi

# create new machine, but don't start it
./scripts/create-lxc.sh "${machine_config}" "migrate"


new_vmid=$(pct list | grep "${hostname}\s" | cut -d' ' -f 1)

log "    New Machine ID: ${new_vmid}"

# should check if mp2 is actually defined or not i suppose
# reparent mp2
pct move-volume "${old_vmid}" mp2 --target-vmid "${new_vmid}" --target-volume mp2

# start new machine
pct start "${new_vmid}"

# delete old machine
pct destroy "${old_vmid}" --purge

log "==> Done"

