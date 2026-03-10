
{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "chart.name" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Define the name of the chart/application.
*/}}
{{- define "app.name" -}}
{{- .Values.appName | default .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Define the version of the chart/application.
*/}}
{{- define "app.version" -}}
{{- .Values.appVersion | default .Chart.Version -}}
{{- end -}}

{{/*
Define the port of the chart/application.
*/}}
{{- define "app.port" -}}
{{- .Values.appPort | default .Values.image.port | default .Values.deployment.port | default 8080 -}}
{{- end -}}

{{/*
Allow the release namespace to be overridden
*/}}
{{- define "app.namespace" -}}
{{- .Values.namespaceOverride | default .Release.Namespace -}}
{{- end -}}

{{/*Create the name of the service account to use*/}}
{{- define "chart.serviceAccountName" -}}
{{- if hasKey .Values.serviceAccount "name" -}}
{{ .Values.serviceAccount.name }}
{{- else if and .Values.deployment.enabled (hasKey .Values.deployment.serviceAccount "name") -}}
{{ .Values.deployment.serviceAccount.name }}
{{- else if and .Values.statefulSet.enabled (hasKey .Values.statefulSet.serviceAccount "name") -}}
{{ .Values.statefulSet.serviceAccount.name }}
{{- else -}}
{{ include "app.name" . }}
{{- end -}}
{{- end -}}

{{/* Shared labels used for selector */}}
{{- define "chart.appLabels" }}
{{- if .suffixName }}
app.kubernetes.io/name: {{ include "app.name" . }}-{{.suffixName}}
{{- else}}
app.kubernetes.io/name: {{ include "app.name" . }}
{{- end }}
app.kubernetes.io/version: {{ include "app.version" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/* Common labels for the whole chart */}}
{{- define "chart.commonLabels" -}}
{{ include "chart.appLabels" . }}
{{- if .Values.teamOwner }}
app.kubernetes.io/teamowner: {{ .Values.teamOwner }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "chart.name" . }}
{{- if .Values.commonLabels }}
{{- range $key, $value := .Values.commonLabels }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/* Common annotations for the whole chart */}}
{{- define "chart.commonAnnotations" }}
helm.sh/chart: {{ include "chart.name" . }}
{{- if .Values.commonAnnotations }}
{{- range $key, $value := .Values.commonAnnotations }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end }}

{{/* Deployment labels */}}
{{- define "chart.deploymentLabels" -}}
{{- end }}

{{/* Deployment annotations */}}
{{- define "chart.deploymentAnnotations" -}}
{{- end }}

{{/*
Renders labels or annotations from either map or list format.
  Map:  {key1: val1, key2: val2}
  List: [{key: key1, value: val1}, {key: key2, value: val2}]
*/}}
{{- define "chart.renderLabels" -}}
{{- if kindIs "slice" . -}}
{{- range . }}
{{ .key }}: {{ .value | quote }}
{{- end }}
{{- else if kindIs "map" . -}}
{{- range $key, $value := . }}
{{ $key }}: {{ $value | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Renders JobSpec fields shared between Job and CronJob.
Accepts a dict with "global" (top-level job/cronJob values) and "job" (per-job values).
Per-job values override global values (specific beats general).

Integer fields: numeric values. Add new numeric K8s fields to $intFields.
String fields: string values. Add new string K8s fields to $stringFields.
Object fields: structured YAML (maps/lists). Add new K8s fields to $objectFields.
*/}}
{{- define "chart.jobSpec" -}}
{{- $global := .global -}}
{{- $job := .job -}}

{{/* Integer fields — cast with int to handle quoted strings. To add a new numeric K8s field, append here */}}
{{- $intFields := list "parallelism" "completions" "backoffLimit" "ttlSecondsAfterFinished" "activeDeadlineSeconds" -}}

{{- range $field := $intFields }}
{{- if hasKey $job $field }}
{{ $field }}: {{ int (index $job $field) }}
{{- else if hasKey $global $field }}
{{ $field }}: {{ int (index $global $field) }}
{{- end }}
{{- end }}

{{/* String fields — rendered as-is. To add a new string K8s field, append here */}}
{{- $stringFields := list "completionMode" "podReplacementPolicy" -}}

{{- range $field := $stringFields }}
{{- if hasKey $job $field }}
{{ $field }}: {{ index $job $field }}
{{- else if hasKey $global $field }}
{{ $field }}: {{ index $global $field }}
{{- end }}
{{- end }}

{{/* Complex object fields — to add a new structured K8s field, append to this list */}}
{{- $objectFields := list "podFailurePolicy" -}}

{{- range $field := $objectFields }}
{{- if hasKey $job $field }}
{{ $field }}:
  {{- toYaml (index $job $field) | nindent 2 }}
{{- else if hasKey $global $field }}
{{ $field }}:
  {{- toYaml (index $global $field) | nindent 2 }}
{{- end }}
{{- end }}

{{- end -}}
