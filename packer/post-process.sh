#!/bin/sh

set -eu

source="$PWD/out/rootfs.tar.gz"
target="$PWD/out/${PACKER_BUILD_NAME}.tar.xz"


temp=$(mktemp -d)
cd "${temp}"

# unpack the built tar file
tar -xf "${source}"

# repack the tarfile, but remove the first folder level which proxmox doesnt' like
tar cfJ "${target}" -C rootfs .

rm "${source}"

cd ..
rm -rf "${temp}"

cp "${target}" /var/lib/vz/template/cache/
