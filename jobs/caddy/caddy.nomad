job "caddy" {
  datacenters = ["*"]

  type = "service"

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "10m"
    auto_revert = false
    canary = 0
  }

  group "app" {
    count = 1

    network {
      port "https" {
        static = 443
      }
      port "http" {
        static = 80
      }
    }

    # service discovery
    service {
      name     = "caddy"
      tags     = ["ingress"]
      port     = "https"
      provider = "nomad"
    }

    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }

    task "caddy" {
      driver = "exec"

      artifact {
        source = "https://caddyserver.com/api/download?os=linux&arch=amd64"
        destination = "local/caddy"
        mode = "file"
      }

      config {
        command = "caddy"
        args    = [ "run", "--config", "local/Caddyfile", "--watch" ]
      }

      template {
        data = file("Caddyfile.tpl")
        destination = "local/Caddyfile"
        change_mode = "noop"
      }

      resources {
        memory = 256
      }
    }
  }
}
