#!/bin/sh

set -eu

# assume we're running on alpine for now
rc-update add local default
rm -rf /etc/local.d # recreated by a mount script