{{/*
Expand the name of the chart.
*/}}
{{- define "octoprint.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "octoprint.fullname" -}}
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
{{- define "octoprint.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "octoprint.labels" -}}
helm.sh/chart: {{ include "octoprint.chart" . }}
{{ include "octoprint.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "octoprint.selectorLabels" -}}
app.kubernetes.io/name: {{ include "octoprint.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "octoprint.name" . }}
{{- end }}

{{/*
OctoPrint specific labels
*/}}
{{- define "octoprint.octoprint.labels" -}}
{{ include "octoprint.labels" . }}
app.kubernetes.io/component: octoprint
{{- end }}

{{- define "octoprint.octoprint.selectorLabels" -}}
{{ include "octoprint.selectorLabels" . }}
app.kubernetes.io/component: octoprint
{{- end }}

{{/*
MJPG-Streamer specific labels
*/}}
{{- define "octoprint.mjpgStreamer.labels" -}}
{{ include "octoprint.labels" . }}
app.kubernetes.io/component: mjpg-streamer
{{- end }}

{{- define "octoprint.mjpgStreamer.selectorLabels" -}}
{{ include "octoprint.selectorLabels" . }}
app.kubernetes.io/component: mjpg-streamer
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "octoprint.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "octoprint.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
