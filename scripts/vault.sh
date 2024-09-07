#!/bin/sh

. ./scripts/util.sh

configure_vault() {
  hostname="$1"

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

create_vault_token() {
  hostname="$1"

  log "--> Populating Secrets"

  # maybe load in policies etc from the machine's dir?
  # i.e. vault policy write ${machine_config}/vault_policy
  policy_name="machine-${hostname}"

  log "    Creating policy ${policy_name}..."

  (cat <<EOF
  path "kv/data/apps/${hostname}/*" {
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

  echo "VAULT_TOKEN='${token}'"
  echo "VAULT_ADDR='http://vault:8200'"

  log "    Done"
}
