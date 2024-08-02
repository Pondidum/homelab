#!/bin/sh

#!/bin/sh

set -eu

log() {
  echo "${LIGHT_BLUE}${1}${COLOR_RESET}" >&2
}

configure_vault() {

  if [ "${hostname}" = "vault" ]; then
    log "--> Skipping secret reading as this is the Vault machine"
    return
  fi

  log "==> Configuring Vault access"

  vault_vmid=$(pct list | grep vault | cut -d" " -f 1)
  if [ -z "${vault_vmid}" ]; then
    log "--> Unable to find Vault container"
    exit 1
  fi
  # workaround for dns being slow in my libvirt instance
  vault_ip=$(dig vault +short)

  while ! vault_token=$(pct pull "${vault_vmid}" /var/lib/vault/.root_token /dev/stdout); do
    log "    waiting for vault to be initialised"
    sleep 1s
  done

  export VAULT_ADDR="http://${vault_ip}:8200"
  export VAULT_TOKEN="${vault_token}"

  while ! vault status; do
    log "    Waiting for Vault to unseal"
    sleep 1s
  done

  log "    Done"
}

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

  log "--> Populating Secrets"

  # maybe load in policies etc from the machine's dir?
  # i.e. vault policy write ${machine_config}/vault_policy
  policy_name="${hostname}-ro"

  log "    Creating policy ${policy_name}..."

  (cat <<EOF
  path "kv/apps/${hostname}/*" {
    capabilities = [ "create", "update", "read", "list", "delete" ]
  }
EOF
) | vault policy write "${policy_name}" -

  log "    Done"
  log "    Creating token..."

  token=$(vault token create \
    -display-name "${hostname}" \
    -policy "${policy_name}" \
    -field token)

  log "    Done"
  log "    Writing secrets to disk"

  echo "VAULT_TOKEN='${token}'" >> "${secrets_file}"
  echo "VAULT_ADDR='http://vault:8200'" >> "${secrets_file}"

  log "    Done"
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
  if [ -z "${machine_config}" ]; then
    log "--> no machine config specified"
    exit 1
  fi

  . "${machine_config}/options"

  if pct list | grep "${hostname}" > /dev/null; then
    log "--> Machine exists, skipping"
    exit 0
  fi

  vmid=$(pvesh get /cluster/nextid)

  log "    New ID:     ${vmid}"
  log "    Template:   ${template}"
  log "    Memory:     ${memory}"
  log "    Root Disk:  ${rootsize}"

  host_dir="/var/lib/lxc/${vmid}/host"

  configure_vault
  populate_host_mount "${machine_config}" "${host_dir}"
  populate_secrets "${hostname}" "${host_dir}/secrets"
  configure_bootscript "${machine_config}" "${host_dir}" "${bootscript:-""}"
  password=$(create_password "${hostname}")

  extra_mounts=""
  if [ -n "${volume:-""}" ]; then
    extra_mounts="--mp2 ${volume}"
  fi

  pct create "${vmid}" "${template_path}/${template}.tar.xz" \
    --hostname "${hostname}"  \
    --memory "${memory}"  \
    --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,ip6=dhcp,type=veth \
    --storage local-lvm \
    --rootfs "local-lvm:${rootsize}" \
    --mp0 "${host_dir},mp=/host" \
    --mp1 "${host_dir}/boot,mp=/etc/local.d" \
    ${extra_mounts} \
    --unprivileged 1  \
    --ssh-public-keys /root/.ssh/authorized_keys  \
    --password="${password}"  \
    --onboot 1 \
    --start 1
}

main "$@"
