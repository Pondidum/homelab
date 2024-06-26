#!/bin/sh

nomad var put "secret/postgres/super" \
  "username=postgres" \
  "password=$(cat /proc/sys/kernel/random/uuid)"