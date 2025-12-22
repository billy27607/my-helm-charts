{{/*
Expand the name of the chart.
*/}}
{{- define "homebridge.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "homebridge.fullname" -}}
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
{{- define "homebridge.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "homebridge.labels" -}}
helm.sh/chart: {{ include "homebridge.chart" . }}
{{ include "homebridge.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "homebridge.selectorLabels" -}}
app.kubernetes.io/name: {{ include "homebridge.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Mosquitto labels
*/}}
{{- define "homebridge.mosquitto.labels" -}}
helm.sh/chart: {{ include "homebridge.chart" . }}
{{ include "homebridge.mosquitto.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Mosquitto selector labels
*/}}
{{- define "homebridge.mosquitto.selectorLabels" -}}
app.kubernetes.io/name: {{ include "homebridge.name" . }}-mosquitto
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
