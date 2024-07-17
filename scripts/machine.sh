#!/bin/sh

set -eu
template_path="/var/lib/vz/template/cache"

machine_config="${1:-""}"
if [ -z "${machine_config}" ]; then
  echo "no machine config specified"
  exit 1
fi

. "${machine_config}/options"


echo "==> Creating ${hostname}"

if pct list | grep "${hostname}" > /dev/null; then
  echo "--> Machine exists, skipping"
  exit 0
fi

vmid=$(pvesh get /cluster/nextid)
echo "--> New ID: ${vmid}"


host_dir="/var/lib/lxc/${vmid}/host"
mkdir -p "${host_dir}"
mkdir -p "${host_dir}/boot"


# write secrets
echo "SECRET=value" > "${host_dir}/secrets"

# configure boot script
if [ -n "${bootscript}" ]; then
  echo "--> configuring boot script"
  cp "${machine_config}/${bootscript}" "${host_dir}/boot/user.start"
  chmod +x "${host_dir}/boot/user.start"
fi

pct create "${vmid}" "${template_path}/${template}" \
  --hostname "${hostname}"  \
  --memory "${memory}"  \
  --net0 name=eth0,bridge=vmbr0,firewall=1,ip=dhcp,ip6=dhcp,type=veth \
  --storage local-lvm \
  --rootfs "local-lvm:${rootsize}" \
  --mp0 "${host_dir},mp=/host" \
  --mp1 "${host_dir}/boot,mp=/etc/local.d" \
  --unprivileged 1  \
  --ssh-public-keys /root/.ssh/authorized_keys  \
  --password="minio"  \
  --onboot 1 \
  --start 1
