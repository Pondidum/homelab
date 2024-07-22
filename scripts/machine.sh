#!/bin/sh

set -eu
template_path="/var/lib/vz/template/cache"

machine_config="${1:-""}"
if [ -z "${machine_config}" ]; then
  echo "no machine config specified"
  exit 1
fi

. "${machine_config}/options"

configure_vault() {

  vault_token=$(pct pull "${vault_vmid}" /var/lib/vault/.root_token /dev/stdout)
  vault_ip=$(dig vault +short)

  # workaround for dns being slow in my libvirt instance
  export VAULT_ADDR="http://${vault_ip}:8200"
  export VAULT_TOKEN="${vault_token}"
}

populate_secrets() {
  hostname="$1"
  secrets_file="$2"

  # get the vault token, but not if we're creating the vault container
  if [ "${hostname}" = "vault" ]; then
    echo "--> Skipping secret reading as this is the Vault machine"
    return
  fi

  echo "--> Populating Secrets"

  vault_vmid=$(pct list | grep vault | cut -d" " -f 1)
  if [ -z "${vault_vmid}" ]; then
    echo "--> Unable to find Vault container"
    return
  fi

  # maybe load in policies etc from the machine's dir?
  # i.e. vault policy write ${machine_config}/vault_policy
  policy_name="${hostname}-ro"

  echo "    Creating policy ${policy_name}..."

  (cat <<EOF
  path "kv/${hostname}/*" {
    capabilities = [ "read", "list" ]
  }
EOF
) | vault policy write "${policy_name}" -

  echo "    Done"
  echo "    Creating token..."

  token=$(vault token create \
    -display-name "${hostname}" \
    -policy "${policy_name}" \
    -field token)

  echo "    Done"
  echo "    Writing secrets to disk"

  echo "VAULT_TOKEN='${token}'" >> "${secrets_file}"

  echo "--> Done"
}

populate_host_mount() {
  config_path="$1"
  host_dir="$2"

  echo "    Creating host directory"
  # ensure the directory isn't reused
  rm -rf "${host_dir}" || true
  mkdir -p "${host_dir}"
  mkdir -p "${host_dir}/boot"

  # copy the machine's contents to the host dir so its accessible to the container
  cp "${config_path}"/* "${host_dir}"

  echo "    Done"
}

configure_bootscript() {
  machine_config="$1"
  host_dir="$2"
  bootscript="$3"

  if [ -z "${bootscript:-""}" ]; then
    return
  fi

  echo "    Configuring boot script"
  cp "${machine_config}/${bootscript}" "${host_dir}/boot/user.start"
  chmod +x "${host_dir}/boot/user.start"

  echo "    Done"
}

main() {
  echo "==> Creating ${hostname}"

  if pct list | grep "${hostname}" > /dev/null; then
    echo "--> Machine exists, skipping"
    exit 0
  fi

  vmid=$(pvesh get /cluster/nextid)
  echo "    New ID: ${vmid}"


  host_dir="/var/lib/lxc/${vmid}/host"

  populate_host_mount "${machine_config}" "${host_dir}"
  populate_secrets "${hostname}" "${host_dir}/secrets"

  configure_bootscript "${machine_config}" "${host_dir}" "${bootscript}"

  extra_mounts=""
  if [ -n "${volume:-""}" ]; then
    extra_mounts="--mp2 ${volume}"
  fi

  pct create "${vmid}" "${template_path}/${template}" \
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
    --password="minio"  \
    --onboot 1 \
    --start 1
}

main "$@"
