#!/bin/sh

set -eu

username="miniflux"
database="miniflux"
password=$(cat /proc/sys/kernel/random/uuid)

nomad var put "nomad/jobs/miniflux" \
  "username=${username}" \
  "password=${password}" \
  "database=${database}"

# export "PGPASSWORD=$(nomad var get -item password secret/postgres/super)"
# export "PGUSER=$(nomad var get -item username secret/postgres/super)"
# export "PGHOST=$(nomad service info -t '{{ (index . 0).Address }}' postgres)"

# psql -c "create role ${username} with login password '${password}';"
# psql -c "create database ${database} with owner ${username};"
# psql "${database}" -c "create extension hstore"

# # restore a backup if needed
# pg_restore -1 -v --dbname "${database}" backup.sql
