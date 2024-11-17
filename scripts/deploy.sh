#!/bin/sh

set -eu

./scripts/machine.sh "machines/vault"
./scripts/machine.sh "machines/dns"
./scripts/machine.sh "machines/lb"
# ./scripts/machine.sh "machines/minio"
