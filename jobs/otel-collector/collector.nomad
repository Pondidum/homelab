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
      tags     = ["otel"]
      port     = "grpc"
      provider = "nomad"
    }

    task "otel-collector" {
      driver = "docker"

      config {
        image = "otel/opentelemetry-collector-contrib:0.92.0"
        args = [ "--config", "local/collector.conf" ]
        ports = [ "grpc" ]
      }

      template {
        data = <<EOF
receivers:
  otlp:
    protocols:
      grpc:

processors:
  attributes:
    actions:
    - action: upsert
      key: environment
      value: local

exporters:
{{- with nomadVar "nomad/jobs/otel-collector" }}
  otlp:
    endpoint: "api.eu1.honeycomb.io:443"
    headers:
      "x-honeycomb-team": "{{ .honeycomb_apikey }}"
{{- end }}

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [attributes]
      exporters: [otlp]
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
