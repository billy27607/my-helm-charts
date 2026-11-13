{{/*
Expand the name of the chart.
*/}}
{{- define "nut-ups.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "nut-ups.fullname" -}}
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
{{- define "nut-ups.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "nut-ups.labels" -}}
helm.sh/chart: {{ include "nut-ups.chart" . }}
{{ include "nut-ups.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "nut-ups.selectorLabels" -}}
app.kubernetes.io/name: {{ include "nut-ups.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Notification credentials for push.sh
*/}}
{{- define "nut-ups.ntfyEnv" -}}
- name: NTFY_TOPIC
  valueFrom:
    secretKeyRef:
      name: {{ include "nut-ups.fullname" . }}
      key: ntfy-topic
- name: NTFY_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "nut-ups.fullname" . }}
      key: ntfy-token
- name: PUSHOVER_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "nut-ups.fullname" . }}
      key: pushover-user
- name: PUSHOVER_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "nut-ups.fullname" . }}
      key: pushover-token
{{- end }}
