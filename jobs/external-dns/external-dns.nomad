job "external-dns" {
  type = "batch"

  periodic {
    crons = ["*/15 * * * *"]
  }

  group "app" {
    count = 1

    task "external-dns" {
      driver = "exec"

      config {
        command = "/bin/sh"
        args = [ "./local/gandi.sh" ]
      }

      vault {}

      template {
        env = true
        destination = "secrets/file.env"
        data = "GANDI_APIKEY='{{ with secret \"kv/data/nomad/jobs/external-dns/gandi\" }}{{ .Data.data.apikey }}{{ end }}'"
      }

      template {
        data = file("gandi.sh")
        destination = "local/gandi.sh"
        change_mode = "noop"
      }

    }
  }
}