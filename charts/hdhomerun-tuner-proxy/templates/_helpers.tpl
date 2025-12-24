{{/*
Expand the name of the chart.
*/}}
{{- define "hdhomerun-tuner-proxy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "hdhomerun-tuner-proxy.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hdhomerun-tuner-proxy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hdhomerun-tuner-proxy.labels" -}}
helm.sh/chart: {{ include "hdhomerun-tuner-proxy.chart" . }}
{{ include "hdhomerun-tuner-proxy.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hdhomerun-tuner-proxy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hdhomerun-tuner-proxy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
