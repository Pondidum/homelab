#!/bin/sh

set -eu

. ./scripts/util.sh

create_proxmox_apikey() {
  hostname="$1"

  log "--> ${hostname}"

  username="lxcapi@pve"
  if ! pveum user list | grep -q "${username}"; then
    log "    creating ${username} user"
    pveum user add "${username}"
  fi

  # space is important here as the token is the user + "!token-name"
  if ! pveum acl list | grep -q "${username} "; then
    log "    configuring user acl"
    pveum acl modify / -users "${username}" -roles PVEAuditor
  fi

  if ! pveum role list | grep -q "vm-reader"; then
    log "    creating vm-reader role"
    pveum role add vm-reader -privs "VM.Audit"
  fi

  token_name="${hostname}-ro"

  if ! pveum user token list "${username}" | grep -q "${token_name}"; then
    log "    creating ${token_name} token"

    output=$(pveum user token add "${username}" "${token_name}" -privsep)
    secret=$(echo "${output}" | sed -nr 's/│ value.*│ (.*) │/\1/p')

    vault kv put -mount=kv \
      "machines/${hostname}/proxmox" \
      "token=${token_name}" \
      "secret=${secret}" >/dev/null 2>&1

  else
    secret=$(vault kv get -field=secret "kv/machines/${hostname}/proxmox")

  fi

  log "    secret: ${secret}"

  if ! pveum acl list | grep -q "${username}!${token_name}"; then
    log "    configuring token acl"
    pveum acl modify "/vms" -tokens "${username}!${token_name}" -roles vm-reader
  fi

  echo "PROXMOX_API='${secret}'"
}
