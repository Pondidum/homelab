job "otel-collector" {
  datacenters = ["*"]
  type = "service"

  group "app" {
    count = 1

    network {
      port "grpc" {
        static = 4317
      }
    }

    service {
      name     = "${JOB}"
      tags     = ["otel", "ingress:enabled"]
      port     = "grpc"
      provider = "nomad"
    }

    task "otel-collector" {
      driver = "docker"

      config {
        image = "otel/opentelemetry-collector-contrib:0.114.0"
        args = [ "--config", "local/collector.conf" ]
        ports = [ "grpc" ]
      }

      vault {}

      template {
        data = <<EOF
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317

exporters:
{{ with secret "kv/data/nomad/jobs/otel-collector/honeycomb" }}
  otlp:
    endpoint: "api.eu1.honeycomb.io:443"
    headers:
      "x-honeycomb-team": "{{ .Data.data.apikey }}"
{{- end }}
  debug:

service:
  pipelines:
    traces:
      receivers:
      - otlp
      processors: []
      exporters:
      - otlp
      - debug
        EOF
        destination = "local/collector.conf"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }

      resources {
        memory = 100
      }
    }

  }
}
