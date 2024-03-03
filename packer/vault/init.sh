#!/sbin/openrc-run

name="Vault server"
description="Vault is a tool for securely accessing secrets"
description_reload="Reload configuration"

extra_started_commands="reload"

command="/usr/sbin/${RC_SVCNAME}"
command_args="${vault_opts}"
command_user="${RC_SVCNAME}:${RC_SVCNAME}"

supervisor=supervise-daemon
output_log="/var/log/${RC_SVCNAME}.log"
error_log="/var/log/${RC_SVCNAME}.log"
respawn_max=0
respawn_delay=10

depend() {
	need net
	after firewall
}

start_pre() {
	checkpath -f -m 0644 -o "$command_user" "$output_log" "$error_log"
	checkpath -d -o "$command_user" "/var/lib/vault"
}

start_post() {
	export VAULT_ADDR=http://localhost:8200

	# we could loop here waiting for the api to be available I suppose
	sleep 5s

	token_store="/var/lib/vault/.root_token"
	unseal_store="/var/lib/vault/.unseal_key"

	status=$(vault status -format json)

	if [ "$(echo "${status}" | jq '.initialized')" = "false" ]; then
	ebegin "Initializing Vault"
		init_json=$(vault operator init -key-shares=1 -key-threshold=1 -format=json)

		echo "${init_json}" | jq -r '.root_token' > "${token_store}"
		echo "${init_json}" | jq -r '.unseal_keys_b64[0]' > "${unseal_store}"

		# should now be "sealed"
		status=$(vault status -format json)
	eend
	fi

	export VAULT_TOKEN=$(cat "${token_store}")

	if [ "$(echo "${status}" | jq '.sealed')" = "true" ]; then
	ebegin "Unsealing Vault..."
		vault operator unseal "$(cat "${unseal_store}")"
	eend
	fi
}

reload() {
	start_pre \
		&& ebegin "Reloading $RC_SVCNAME configuration" \
		&& $supervisor "$RC_SVCNAME" --signal HUP
	eend $?
}

# after