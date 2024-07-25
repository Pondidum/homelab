#!/bin/sh

# this script is run on machine boot, so needs to be idempotent

set -eu

# wait for the token file to exist
token_path="/var/lib/vault/.root_token"

echo "==> Configuring Vault"

while ! [ -f "${token_path}" ]; do
  echo "    Token not created yet, sleeping..."
  sleep 1s
done

echo "--> Token found!"

export VAULT_TOKEN="$(cat "${token_path}")"
export VAULT_ADDR="http://127.0.0.1:8200"

# wait for vault to be ready

while ! vault status 2> /dev/null; do
  echo "    Waiting for Vault..."
  sleep 1s
done

echo "--> Vault ready"

vault secrets enable -version '2' 'kv' || true

echo "==> Done"