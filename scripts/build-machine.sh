#!/bin/sh

set -eu

machine_name="${1}"

cd "packer/${machine_name}"

packer init .
packer build .
