#!/sbin/openrc-run

name="MinIO"
description="Minio Block Storage Server"

: ${data_dirs:="/var/lib/minio/data"}
: ${logfile="/var/log/$RC_SVCNAME.log"}
: ${command_user:="minio:minio"}
: ${healthcheck_timer:=30}
: ${respawn_delay:=5}
: ${respawn_max:=0}

command="/usr/bin/minio"
command_args="server
  ${certs_dir:+"--certs-dir=$certs_dir"}
  ${command_args-"--quiet --anonymous"}
  $data_dirs
  "
command_background="yes"
pidfile="/run/$RC_SVCNAME.pid"
output_log="$logfile"
error_log="$logfile"

depend() {
  need localmount net
  use dns
}

start_pre() {
  # Replace root user and password placeholders with random strings.
  if [ -z "$MINIO_ROOT_USER" ] || [ -z "$MINIO_ROOT_PASSWORD" ]; then

    einfo "==> Configuring root user"
    set -a
    source /host/secrets
    set +a

    if ! json="$(vault kv get -format=json kv/apps/minio/root)"; then

      einfo "    Credentials not found in Vault, generating"

      vault kv put -mount=kv apps/minio/root \
        "username=minio" \
        "password=$(cat /proc/sys/kernel/random/uuid)"

      json="$(vault kv get -format=json kv/apps/minio/root)"
    fi

    user=$(echo "${json}" | jq -r .data.data.username)
    pass=$(echo "${json}" | jq -r .data.data.password)

    einfo "    Updating config with credentials from Vault"

    sed -Ei \
      -e 's/^(MINIO_ROOT_USER)=""/\1="'"${user}"'"/' \
      -e 's/^(MINIO_ROOT_PASSWORD)=""/\1="'"${pass}"'"/' \
      "/etc/conf.d/${RC_SVCNAME}"

    export "MINIO_ROOT_USER=${user}"
    export "MINIO_ROOT_PASSWORD=${pass}"

    einfo "--> Done"
  fi

  # If the first directory is a local directory (starts with "/"), ensure it exists.
  case "$data_dirs" in /*)
    local first_dir=$(echo "$data_dirs" | grep -Eo '\S+' | head -n1)

    checkpath --directory --mode 0700 --owner "$command_user" "$first_dir" || return 1
  esac

  if [ "$logfile" ]; then
    checkpath --file --mode 0640 --owner "$command_user" "$logfile" || return 1
  fi
}

healthcheck() {
  [ -x /usr/bin/curl ] || return 0
  /usr/bin/curl -q "${MINIO_ADDRESS:-"localhost:9000"}"/minio/health/ready
}
