#!/bin/sh

set -eu

. ./scripts/util.sh
. ./scripts/vault.sh
. ./scripts/proxmox.sh

create_password() {
  hostname="$1"
  password="$(cat /proc/sys/kernel/random/uuid)"

  if [ "${hostname}" != "vault" ]; then
    vault kv put -mount=kv \
      "machines/${hostname}/root" \
      "username=root" \
      "password=${password}" >/dev/null 2>&1
  fi

  log "--> ${hostname} Password: ${password}"

  echo "${password}"
}

populate_secrets() {
  hostname="$1"
  secrets_file="$2"

  # get the vault token, but not if we're creating the vault container
  if [ "${hostname}" = "vault" ]; then
    return
  fi

  create_proxmox_apikey "${hostname}" >> "${secrets_file}"
  create_vault_token "${hostname}" >> "${secrets_file}"
}

populate_host_mount() {
  config_path="$1"
  host_dir="$2"

  log "    Creating host directory"
  # ensure the directory isn't reused
  rm -rf "${host_dir}" || true
  mkdir -p "${host_dir}"
  mkdir -p "${host_dir}/boot"

  # copy the machine's contents to the host dir so its accessible to the container
  cp "${config_path}"/* "${host_dir}"

  log "    Done"
}

configure_bootscript() {
  machine_config="$1"
  host_dir="$2"
  bootscript="$3"

  if [ -z "${bootscript:-""}" ]; then
    return
  fi

  log "    Configuring boot script"
  cp "${machine_config}/${bootscript}" "${host_dir}/boot/user.start"
  chmod +x "${host_dir}/boot/user.start"

  log "    Done"
}

main() {
  template_path="/var/lib/vz/template/cache"

  machine_config="${1:-""}"
  migration="${2:-""}"

  if [ -z "${machine_config}" ]; then
    log "--> no machine config specified"
    exit 1
  fi

  . "${machine_config}/options"

  if pct list | grep "${hostname}\s" > /dev/null; then
    log "--> Machine exists, skipping"
    exit 0
  fi

  vmid=$(pvesh get /cluster/nextid)
  storage=$(pvesm status -content rootdir | tail -1 | cut -d' ' -f 1)

  log "    New ID:     ${vmid}"
  log "    Template:   ${template}"
  log "    Memory:     ${memory}"
  log "    Root Disk:  ${rootsize}"
  log "    Storage:    ${storage}"

  host_dir="/var/lib/lxc/${vmid}/host"

  configure_vault "${hostname}"
  populate_host_mount "${machine_config}" "${host_dir}"
  populate_secrets "${hostname}" "${host_dir}/secrets"
  configure_bootscript "${machine_config}" "${host_dir}" "${bootscript:-""}"
  password=$(create_password "${hostname}")

  extra_mounts=""
  if [ -n "${volume:-""}" ] && [ -z "${migration}" ]; then
    extra_mounts="--mp2 ${storage}:${volume}"
  fi

  start="1"
  if [ -n "${migration}" ]; then
    start="0"
  fi

  pct create "${vmid}" "${template_path}/${template}.tar.xz" \
    --hostname "${hostname}"  \
    --memory "${memory}"  \
    --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,ip6=dhcp,type=veth \
    --storage "${storage}" \
    --rootfs "${storage}:${rootsize}" \
    --mp0 "${host_dir},mp=/host" \
    --mp1 "${host_dir}/boot,mp=/etc/local.d" \
    ${extra_mounts} \
    --unprivileged 1  \
    --ssh-public-keys /root/.ssh/authorized_keys  \
    --password="${password}"  \
    --onboot 1 \
    --start "${start}"
}

main "$@"
