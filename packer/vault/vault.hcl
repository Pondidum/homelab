api_addr = "http://0.0.0.0:8200"
ui = true

listener "tcp" {
  tls_disable = 1
  address = "0.0.0.0:8200"
}

disable_mlock = true
storage "file" {
  path ="/var/lib/vault"
}
