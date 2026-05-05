
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
app.kubernetes.io/name: {{ printf "%s-%s" (include "app.name" .) .suffixName | trunc 63 | trimSuffix "-" }}
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

WARNING: If activeDeadlineSeconds is set, Kubernetes will terminate the Job when
the deadline expires, even if backoffLimit retries remain. These two fields interact
and users should understand the implications of setting both.

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

{{/*
Build a container image reference with per-resource override and inheritance support.
Inputs: .root (template context), .image (per-resource: string or map), .defaultImage (top-level image map)
Output: registry/repository[:tag] string
Fallback chain (tag): resource image.tag → defaultImage.tag → .root.Values.appVersion → (no tag)
If a resource-level image map explicitly sets tag to empty (tag: ""), it clears inherited tags.
String form (.image: "reg/repo:tag") is returned as-is for backward compatibility.
*/}}
{{- define "chart.imageReference" -}}
{{- $root := .root }}
{{- $image := .image }}
{{- $defaultImage := .defaultImage | default (dict) }}
{{/* If image is a string (not a map), use it directly for backward compatibility */}}
{{- if and $image (not (kindIs "map" $image)) }}
{{- if kindIs "string" $image }}
{{- toString $image }}
{{- else }}
{{- fail (printf "image override must be a string or map, got %T" $image) }}
{{- end }}
{{- else }}
{{/* Normalize inputs: derive effective registry/repository/tag once */}}
{{- $effectiveImage := dict }}
{{- if and (kindIs "map" $image) $image }}
{{- $effectiveImage = $image }}
{{- else if $defaultImage }}
{{- $effectiveImage = $defaultImage }}
{{- end }}
{{- if $effectiveImage }}
{{- $registryRaw := $effectiveImage.registry | default $defaultImage.registry | default "docker.io" }}
{{- $registry := trimSuffix "/" $registryRaw }}
{{- $repository := $effectiveImage.repository | default $defaultImage.repository | default "" }}
{{/* Validate: repository is required to form a valid image reference */}}
{{- if not $repository }}
{{- fail "image.repository is required after inheritance (set at top-level image.repository or resource-level image.repository)" }}
{{- end }}
{{/* Validate: digests in repository are not supported in map mode — use string form instead */}}
{{- if contains "@" $repository }}
{{- fail "image.repository must not contain a digest in map form — use a full image string instead (e.g. <resource>.image: \"registry/repo@sha256:...\")" }}
{{- end }}
{{/* Validate: repository should not include a registry host in map form.
Catches known public registries, localhost (with or without port), port-based hosts,
and any host starting with "registry." (e.g. registry.example.com).
Dotted namespace paths like my.team/service remain valid. */}}
{{- $repositoryParts := splitList "/" $repository }}
{{- $repositoryFirstPart := index $repositoryParts 0 }}
{{- $knownRegistryHosts := list "docker.io" "ghcr.io" "quay.io" "gcr.io" "k8s.gcr.io" "registry.k8s.io" "mcr.microsoft.com" "public.ecr.aws" "index.docker.io" }}
{{- $hasRegistryPort := contains ":" $repositoryFirstPart }}
{{- $isKnownRegistryHost := has $repositoryFirstPart $knownRegistryHosts }}
{{- $isLocalRegistry := eq $repositoryFirstPart "localhost" }}
{{- $isRegistryPrefixed := hasPrefix "registry." $repositoryFirstPart }}
{{- if and (ge (len $repositoryParts) 2) (or
  $hasRegistryPort
  $isLocalRegistry
  $isKnownRegistryHost
  $isRegistryPrefixed
) }}
{{- fail (printf "image.repository must not include a registry hostname in map form — set image.registry separately (got: %s)" $repository) }}
{{- end }}
{{- $tag := "" }}
{{- if and (kindIs "map" $image) (hasKey $image "tag") }}
{{- $explicitTag := index $image "tag" }}
{{- if not (eq $explicitTag nil) }}
{{- $tag = $explicitTag }}
{{- else }}
{{- $tag = ($defaultImage.tag | default $root.Values.appVersion | default "") }}
{{- end }}
{{- else }}
{{- $tag = ($defaultImage.tag | default $root.Values.appVersion | default "") }}
{{- end }}
{{- $imageRef := printf "%s/%s" $registry $repository }}
{{- if $tag }}
{{- printf "%s:%s" $imageRef (toString $tag) }}
{{- else }}
{{- $imageRef }}
{{- end }}
{{- else }}
{{- fail "chart.imageReference: could not resolve image — set image.repository at the top level or per resource" }}
{{- end }}
{{- end -}}
{{- end -}}
