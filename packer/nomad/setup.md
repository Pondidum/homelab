nomad acl bootstrap -json

```json
{
  "ExpirationTTL": "",
  "AccessorID": "44d81033-4a12-920a-e448-e616b96f1ae0",
  "SecretID": "6f02e434-cc0b-494b-ab66-272591144787",
  "Name": "Bootstrap Token",
  "Type": "management",
  "Policies": null,
  "Roles": null,
  "Global": true,
  "CreateTime": "2024-04-15T21:29:31.001722876Z",
  "CreateIndex": 23,
  "ModifyIndex": 23
}
```

export NOMAD_TOKEN="6f02e434-cc0b-494b-ab66-272591144787"


Vault Machine:

```shell
export VAULT_ADDR=http://localhost:8200
export "VAULT_TOKEN=$(cat /var/lib/vault/.root_token)"

vault auth enable -path "jwt-nomad" "jwt"

echo '{
  "jwks_url": "http://nomad-dev:4646/.well-known/jwks.json",
  "jwt_supported_algs": ["RS256", "EdDSA"],
  "default_role": "nomad-workloads"
}' > auth-jwt-nomad-dev.json

vault write auth/jwt-nomad/config '@auth-jwt-nomad-dev.json'

echo '{
  "role_type": "jwt",
  "bound_audiences": ["vault.io"],
  "user_claim": "/nomad_job_id",
  "user_claim_json_pointer": true,
  "claim_mappings": {
    "nomad_namespace": "nomad_namespace",
    "nomad_job_id": "nomad_job_id",
    "nomad_task": "nomad_task"
  },
  "token_type": "service",
  "token_policies": ["nomad-workloads"],
  "token_period": "30m",
  "token_explicit_max_ttl": 0
}
' > role-nomad-workloads.json

vault write auth/jwt-nomad/role/nomad-workloads '@role-nomad-workloads.json'

accessor=$(vault auth list -format=json | jq -r '.["jwt-nomad/"].accessor')

cat <<EOF > policy-nomad-workloads.hcl
path "kv/data/{{identity.entity.aliases.${accessor}.metadata.nomad_namespace}}/{{identity.entity.aliases.${accessor}.metadata.nomad_job_id}}/*" {
  capabilities = ["read"]
}

path "kv/data/{{identity.entity.aliases.${accessor}.metadata.nomad_namespace}}/{{identity.entity.aliases.${accessor}.metadata.nomad_job_id}}" {
  capabilities = ["read"]
}

path "kv/metadata/{{identity.entity.aliases.${accessor}.metadata.nomad_namespace}}/*" {
  capabilities = ["list"]
}

path "kv/metadata/*" {
  capabilities = ["list"]
}
EOF

vault policy write 'nomad-workloads' 'policy-nomad-workloads.hcl'

vault secrets enable -version '2' 'kv'
```