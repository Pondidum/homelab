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
  handle /{{ .Name | toLower }}* {
    reverse_proxy {{ .Address }}:{{ .Port}}
  }
  {{- end }}
  {{- end }}
  {{- end }}

  handle {
    respond "Oletko eksynyt??"
  }
}
