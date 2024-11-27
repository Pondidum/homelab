{
	auto_https off
	servers {
		protocols h1 h2 h3 h2c
	}
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
				{{- if .Tags | contains "ingress:grpc" }}

http://{{ .Name | toLower }}.svc.verstas.xyz:8000 {
	reverse_proxy h2c://{{ .Address }}:{{ .Port }}
}

				{{- else }}

http://{{ .Name | toLower }}.svc.verstas.xyz:8000 {
	reverse_proxy {{ .Address }}:{{ .Port }}
}

				{{- end }}
			{{- end }}
		{{- end }}
	{{- end }}
{{- end }}

:8000 {
	handle {
		respond "En mä tiedä"
	}
}
