job "noutaja" {
  datacenters = ["*"]

  type = "service"

  group "app" {
    count = 1

    network {
      port "http" {
        static = 5959
      }
    }

    ephemeral_disk {
      migrate = true
      size = 500
    }

    # service discovery
    service {
      name     = "noutaja"
      port     = "http"
      provider = "nomad"
    }

    task "noutaja" {
      driver = "exec"

      artifact {
        source = "https://github.com/Pondidum/Noutaja/releases/download/eb2343e/noutaja-linux-arm64"
        destination = "local/noutaja"
        mode = "file"
      }

      config {
        command = "noutaja"
        args    = [ "server", "--cache-dir", "${NOMAD_ALLOC_DIR}/data" ]
      }

      env {
        OTEL_EXPORTER_OTLP_ENDPOINT = "//${attr.unique.network.ip-address}:4317"
        OTEL_EXPORTER_OTLP_INSECURE = "true"
      }

      resources {
        memory = 100
      }
    }
  }
}
