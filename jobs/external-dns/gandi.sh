#!/bin/sh

set -eu

if [ -z "${GANDI_APIKEY:-""}" ]; then
  echo "You must set GANDI_APIKEY" >&2
  exit 1
fi

echo "==> External DNS Update"

domain="sammalmaa.fi"
record="koti"

external_ip=$(curl -sSL --url "https://api.ipify.org")
dns_ip=$(curl -sSL \
  --url "https://api.gandi.net/v5/livedns/domains/${domain}/records/${record}/A" \
  --header "Authorization: Apikey ${GANDI_APIKEY}" \
  | jq -r ".rrset_values[0]")

echo "    external ip: ${external_ip}"
echo "    dns ip:      ${dns_ip}"

if [ "${dns_ip}" = "${external_ip}" ]; then
  echo "--> Records match, exiting"
  exit 0
fi

echo "--> Updating DNS IP"
curl -sSL \
  -X PUT \
  --url "https://api.gandi.net/v5/livedns/domains/${domain}/records/${record}/A" \
  --header "Authorization: Apikey ${GANDI_APIKEY}" \
  --header "Content-Type: application/json" \
  --data "{ \"rrset_values\": [ \"${external_ip}\" ], \"rrset_ttl\": 300 }"

echo "==> Done"