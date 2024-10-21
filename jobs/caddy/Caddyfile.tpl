{
  auto_https off
	log default {
		output stdout
		format json
		include http.log.access admin.api
	}
}

:80 {

  {{- range nomadServices }}
    {{- range nomadService .Name }}
      {{- if .Tags | contains "ingress:enabled" }}
        {{- if .Tags | contains "ingress:external" }}
  handle /{{ .Name | toLower }}* {
    reverse_proxy {{ .Address }}:{{ .Port}}
  }
        {{- end }}
      {{- end }}
    {{- end }}
  {{- end }}

  handle {
    respond "Oletko eksynyt??"
  }
}

{{- range nomadServices }}
  {{- range nomadService .Name }}
    {{- if .Tags | contains "ingress:enabled" }}
      {{- if not (.Tags | contains "ingress:external") }}
http://{{ .Name | toLower }}.svc.verstas.xyz:8000 {
  reverse_proxy {{ .Address }}:{{ .Port}}
}

      {{- end }}
    {{- end }}
  {{- end }}
{{- end }}

:8000 {
  handle {
    respond "En mä tiedä"
  }
}
