{{/*
Expand the name of the chart.
*/}}
{{- define "mongo-claimcheck.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "mongo-claimcheck.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "mongo-claimcheck.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "mongo-claimcheck.labels" -}}
app.kubernetes.io/name: {{ include "mongo-claimcheck.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: "{{ .Chart.AppVersion }}"
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
ServiceAccount name
*/}}
{{- define "mongo-claimcheck.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "mongo-claimcheck.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
"default"
{{- end -}}
{{- end -}}