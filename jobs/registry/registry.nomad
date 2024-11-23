job "registry" {

  group "app" {
    count = 1

    network {
      port "http" { to = 5000 }
    }

    ephemeral_disk {
      migrate = true
      sticky = true
      size = 1000
    }

    service {
      name     = "${JOB}"
      tags     = ["ingress:enabled"]
      port     = "http"
      provider = "nomad"
    }

    task "registry" {
      driver = "docker"

      config {
        image = "registry:2"
        ports = [ "http" ]
        volumes = [
          "data:/var/lib/registry"
        ]
      }

      env {
        REGISTRY_STORAGE_FILESYSTEM_ROOTDIRECTORY = "/var/lib/registry"
      }

      resources {
        memory = 50
      }
    }
  }
}
