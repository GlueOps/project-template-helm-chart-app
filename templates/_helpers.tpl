
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
Fallback chain (tag): resource image.tag → defaultImage.tag → .root.Values.appVersion → optionally .root.Chart.Version → fail if useChartVersionAsTagFallback=false and all prior sources unset
String form (.image: "reg/repo:tag" or "reg/repo@sha256:...") is returned verbatim for backward compatibility and to allow references that cannot be expressed in map form. Map form supports digest pinning via tag (e.g. tag: "v1@sha256:...").
Notes:
- .image: {} (explicit empty map) is treated as "no override" and inherits from defaultImage, matching the behavior of an unset .image.
- .root.Values.appVersion is consumed by sprig's `default` and is therefore only honored when truthy under Go-template rules; non-string or falsey values (e.g. 0, false) are silently treated as unset. Set appVersion as a string per Helm convention.
- useChartVersionAsTagFallback is only honored under the top-level `image:` map. Setting it on a per-resource `image:` map is rejected with an explicit fail (not silently ignored).
- registry, repository, and tag must be strings when present. Non-string scalars (numbers, bools, lists, maps) are rejected with a kind-level error rather than coerced via toString.
*/}}
{{- define "chart.imageReference" -}}
{{- $root := .root }}
{{- $image := .image }}
{{- $defaultImage := .defaultImage | default (dict) }}
{{/*
Dispatch on the *kind* of $image (not its truthiness) so that falsey scalars
(0, false, 0.0, empty list) are rejected loudly instead of being silently
treated as "unset" and inheriting. nil/unset is the only non-string,
non-map value allowed — it explicitly means "inherit from defaultImage".
Reject every other type with an actionable error.
*/}}
{{- $imageKind := kindOf $image }}
{{- if eq $imageKind "string" }}
{{/* String form (.image: "reg/repo:tag") returned verbatim for backward compat. Empty/whitespace string is treated as unset and inherits from defaultImage. */}}
{{- $trimmedImage := trim $image }}
{{- if ne $trimmedImage "" }}
{{- $trimmedImage }}
{{- else if $defaultImage }}
{{- include "chart.imageReference" (dict "root" $root "image" nil "defaultImage" $defaultImage) }}
{{- else }}
{{- fail "image override is empty/whitespace-only and no top-level image map is set to inherit from — set .Values.image.repository or provide a non-empty image override" }}
{{- end }}
{{- else if and (ne $imageKind "map") (ne $imageKind "invalid") }}
{{- fail (printf "image override must be a string (e.g. \"registry/repo:tag\") or a map with registry/repository/tag fields, got unsupported type %s for value: %v" $imageKind $image) }}
{{- else }}
{{/* Reject per-resource useChartVersionAsTagFallback: only the top-level flag is honored. Failing fast prevents users from silently relying on a per-resource setting that has no effect. */}}
{{- if and (kindIs "map" $image) (hasKey $image "useChartVersionAsTagFallback") }}
{{- fail "image.useChartVersionAsTagFallback is only supported under the top-level `image:` map (e.g. `image.useChartVersionAsTagFallback: false`), not per-resource." }}
{{- end }}
{{/* Normalize inputs: derive effective registry/repository/tag once */}}
{{- $effectiveImage := dict }}
{{- if and (kindIs "map" $image) $image }}
{{- $effectiveImage = $image }}
{{- else if $defaultImage }}
{{- $effectiveImage = $defaultImage }}
{{- end }}
{{- if $effectiveImage }}
{{- $registry := $effectiveImage.registry | default $defaultImage.registry | default "docker.io" }}
{{- $repository := $effectiveImage.repository | default $defaultImage.repository | default "" }}
{{/* Validate: registry and repository must be strings. Report the *kind* (not the value) so users see what's wrong, not just the literal they typed. */}}
{{- if not (kindIs "string" $registry) }}
{{- fail (printf "image.registry must be a string, got %s (value: %v)" (kindOf $registry) $registry) }}
{{- end }}
{{- if not (kindIs "string" $repository) }}
{{- fail (printf "image.repository must be a string, got %s (value: %v)" (kindOf $repository) $repository) }}
{{- end }}
{{/* Validate: repository is required to form a valid image reference */}}
{{- if not $repository }}
{{- fail "image.repository is required after inheritance (set at top-level image.repository or resource-level image.repository)" }}
{{- end }}
{{/* Validate: digests in repository are not supported in map mode — use string form instead */}}
{{- if contains "@" $repository }}
{{- fail "image.repository must not contain a digest in map form — use a full image string (e.g. deployment.image: \"registry/repo@sha256:...\")" }}
{{- end }}
{{/*
Validate raw tag inputs *before* sprig `default` (below) swallows falsey values. A user-provided
`tag: 0` or `tag: false` would otherwise be silently treated as unset and fall through to
appVersion / chart version. Check the per-resource and top-level tag explicitly. Per-resource is
only checked when an override is actually present (i.e. $image is a non-empty map) — otherwise
$effectiveImage IS $defaultImage and we would double-report. An empty string is permitted because
it is the documented "unset" sentinel.
*/}}
{{- if and (kindIs "map" $image) $image (hasKey $image "tag") }}
{{- $resourceTag := get $image "tag" }}
{{- if and (ne (kindOf $resourceTag) "invalid") (not (kindIs "string" $resourceTag)) }}
{{- fail (printf "image.tag (resource) must be a string, got %s (value: %v)" (kindOf $resourceTag) $resourceTag) }}
{{- end }}
{{- end }}
{{- if hasKey $defaultImage "tag" }}
{{- $topTag := get $defaultImage "tag" }}
{{- if and (ne (kindOf $topTag) "invalid") (not (kindIs "string" $topTag)) }}
{{- fail (printf "image.tag (top-level) must be a string, got %s (value: %v)" (kindOf $topTag) $topTag) }}
{{- end }}
{{- end }}
{{- $tag := $effectiveImage.tag | default $defaultImage.tag | default $root.Values.appVersion | default "" }}
{{- $useChartVersionFallback := true }}
{{- if and $root.Values.image (hasKey $root.Values.image "useChartVersionAsTagFallback") }}
{{- $rawUseChartVersionFallback := $root.Values.image.useChartVersionAsTagFallback }}
{{- if kindIs "bool" $rawUseChartVersionFallback }}
{{- $useChartVersionFallback = $rawUseChartVersionFallback }}
{{- else if kindIs "string" $rawUseChartVersionFallback }}
{{- $normalizedUseChartVersionFallback := (lower (trim $rawUseChartVersionFallback)) }}
{{- if eq $normalizedUseChartVersionFallback "false" }}
{{- $useChartVersionFallback = false }}
{{- else if eq $normalizedUseChartVersionFallback "true" }}
{{- $useChartVersionFallback = true }}
{{- else }}
{{- fail (printf "image.useChartVersionAsTagFallback must be 'true' or 'false' (or omitted for default), got: %q" $rawUseChartVersionFallback) }}
{{- end }}
{{- else }}
{{- fail (printf "image.useChartVersionAsTagFallback must be a bool or string ('true'/'false'), got unsupported type for value: %v" $rawUseChartVersionFallback) }}
{{- end }}
{{- end }}
{{- if and (not $tag) $useChartVersionFallback }}
{{- $tag = ($root.Chart.Version | default "") }}
{{- end }}
{{- if and (not $tag) (not $useChartVersionFallback) }}
{{- fail (printf "image.tag and appVersion are both unset, and image.useChartVersionAsTagFallback is false. Chart rendering is blocked to prevent an untagged image reference (%s/%s), which is non-deterministic and unsafe. Set image.tag or appVersion explicitly, or set image.useChartVersionAsTagFallback to true." $registry $repository) }}
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
