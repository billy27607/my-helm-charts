{{/*
Expand the name of the chart.
*/}}
{{- define "frontst.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "frontst.fullname" -}}
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
{{- define "frontst.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "frontst.labels" -}}
helm.sh/chart: {{ include "frontst.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Homebridge labels
*/}}
{{- define "frontst.homebridge.labels" -}}
{{ include "frontst.labels" . }}
{{ include "frontst.homebridge.selectorLabels" . }}
{{- end }}

{{- define "frontst.homebridge.selectorLabels" -}}
app.kubernetes.io/name: {{ include "frontst.name" . }}-homebridge
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: homebridge
{{- end }}

{{/*
Mosquitto labels
*/}}
{{- define "frontst.mosquitto.labels" -}}
{{ include "frontst.labels" . }}
{{ include "frontst.mosquitto.selectorLabels" . }}
{{- end }}

{{- define "frontst.mosquitto.selectorLabels" -}}
app.kubernetes.io/name: {{ include "frontst.name" . }}-mosquitto
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: mosquitto
{{- end }}

{{/*
Z-Wave JS labels
*/}}
{{- define "frontst.zwavejs.labels" -}}
{{ include "frontst.labels" . }}
{{ include "frontst.zwavejs.selectorLabels" . }}
{{- end }}

{{- define "frontst.zwavejs.selectorLabels" -}}
app.kubernetes.io/name: {{ include "frontst.name" . }}-zwavejs
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: zwavejs
{{- end }}

{{/*
Scrypted labels
*/}}
{{- define "frontst.scrypted.labels" -}}
{{ include "frontst.labels" . }}
{{ include "frontst.scrypted.selectorLabels" . }}
{{- end }}

{{- define "frontst.scrypted.selectorLabels" -}}
app.kubernetes.io/name: {{ include "frontst.name" . }}-scrypted
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: scrypted
{{- end }}
