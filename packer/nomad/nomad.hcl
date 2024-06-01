data_dir  = "/opt/nomad/data"
bind_addr = "0.0.0.0"

server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
  servers = ["127.0.0.1"]

  host_volume "host" {
    path = "/opt/nomad/volumes/host"
    read_only = false
  }
}

vault {
  enabled = true
  address = "http://vault:8200"

  default_identity {
    aud = ["vault.io"]
    ttl = "1h"
  }
}