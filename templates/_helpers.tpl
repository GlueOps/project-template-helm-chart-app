
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
- useChartVersionAsTagFallback accepts a bool, or a string (case-insensitive, surrounding whitespace tolerated): `"true"`, `"True"`, `" FALSE "`, etc. are all valid. Any other string is rejected.
- registry and repository must be strings when present. Non-string scalars (numbers, bools, lists, maps) are rejected with a kind-level error rather than coerced via toString. Surrounding whitespace is trimmed; an interior space (e.g. `repository: "my app"`) is rejected because it produces an invalid image reference.
- tag is permissive on type: truthy non-string scalars (e.g. unquoted YAML numbers like `tag: 5.6`) are coerced via toString. Only falsy non-string scalars (`tag: 0`, `tag: false`, `tag: []`) are rejected, because sprig `default` would silently swallow them and inherit appVersion / chart version. After resolution, the effective tag is trimmed of surrounding whitespace; interior whitespace (e.g. `tag: "v 1"`) is rejected because it produces a malformed image reference (and breaks YAML rendering when surrounding-only).
*/}}
{{- define "chart.imageReference" -}}
{{/* $root must be the helm template root context (typically $ or .Root). Not validated; misuse will surface as a low-level field-not-found error on $root.Values / $root.Chart. */}}
{{- $root := .root }}
{{- $image := .image }}
{{- $defaultImage := .defaultImage }}
{{/*
Validate the helper's own parameter contract: $defaultImage must be a map when set.
A user misconfiguring the top-level value as a scalar (e.g. `--set image=ghcr.io/foo:v1`,
forgetting that string-form overrides belong on per-resource <resource>.image, not the
top-level image map) would otherwise crash deep inside the helper with a low-level
`can't evaluate field registry in type string` error. Fail loudly with an actionable
message at the helper boundary instead.

We must validate kind *before* defaulting to an empty dict, because sprig `default (dict)`
swallows every Go-template-falsey value (false, 0, 0.0, [], "") and would substitute an
empty map — masking the wrong-type input from the kind check below. Only the truly-unset
(nil) case should fall through to the empty-dict default.
*/}}
{{- $defaultImageKind := kindOf $defaultImage }}
{{- if eq $defaultImageKind "invalid" }}
{{- $defaultImage = (dict) }}
{{- else if not (kindIs "map" $defaultImage) }}
{{- fail (printf ".Values.image must be a map (with registry/repository/tag fields), got %s (value: %v). If you intended a per-resource string override, set <resource>.image instead (e.g. deployment.image: \"ghcr.io/foo:v1\")." $defaultImageKind $defaultImage) }}
{{- end }}
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
{{- end }}{{/* Normalize inputs: derive effective registry/repository/tag once */}}
{{- $effectiveImage := dict }}
{{- if and (kindIs "map" $image) $image }}
{{- $effectiveImage = $image }}
{{- else if $defaultImage }}
{{- $effectiveImage = $defaultImage }}
{{- end }}
{{- if $effectiveImage }}
{{/*
Validate raw registry/repository inputs *before* sprig `default` (below) swallows falsey
scalars (0, false, []). Same falsey-non-string silent-coercion class as image.tag: a typo
like `registry: 0` would otherwise be silently dropped and inherit "docker.io", hiding
the bug. Truthy non-string scalars are intentionally NOT rejected here — the post-default
`kindIs "string"` checks below catch those and report them with the actual kind.
Per-resource is checked only when an override is actually present so we don't double-report.
*/}}
{{- if and (kindIs "map" $image) (hasKey $image "registry") }}
{{- $r := get $image "registry" }}
{{- if and (ne (kindOf $r) "invalid") (not (kindIs "string" $r)) (not $r) }}
{{- fail (printf "image.registry (resource) is a falsey non-string value which would be silently swallowed; got %s (value: %v). Quote it or remove it." (kindOf $r) $r) }}
{{- end }}
{{- end }}
{{- if hasKey $defaultImage "registry" }}
{{- $r := get $defaultImage "registry" }}
{{- if and (ne (kindOf $r) "invalid") (not (kindIs "string" $r)) (not $r) }}
{{- fail (printf "image.registry (top-level) is a falsey non-string value which would be silently swallowed; got %s (value: %v). Quote it or remove it." (kindOf $r) $r) }}
{{- end }}
{{- end }}
{{- if and (kindIs "map" $image) (hasKey $image "repository") }}
{{- $r := get $image "repository" }}
{{- if and (ne (kindOf $r) "invalid") (not (kindIs "string" $r)) (not $r) }}
{{- fail (printf "image.repository (resource) is a falsey non-string value which would be silently swallowed; got %s (value: %v). Quote it or remove it." (kindOf $r) $r) }}
{{- end }}
{{- end }}
{{- if hasKey $defaultImage "repository" }}
{{- $r := get $defaultImage "repository" }}
{{- if and (ne (kindOf $r) "invalid") (not (kindIs "string" $r)) (not $r) }}
{{- fail (printf "image.repository (top-level) is a falsey non-string value which would be silently swallowed; got %s (value: %v). Quote it or remove it." (kindOf $r) $r) }}
{{- end }}
{{- end }}
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
{{/*
Normalize: trim surrounding whitespace from registry/repository. Users routinely paste
registry URLs from web UIs which carry stray spaces; without this, the chart silently
renders an invalid image reference (e.g. `docker.io/  podinfo  :v1`) that K8s rejects far
from the source of the typo. After trimming, reject interior spaces and empty values
because they cannot form a valid OCI image reference.
*/}}
{{- $registry = trim $registry }}
{{- $repository = trim $repository }}
{{- if eq $registry "" }}
{{- fail "image.registry is empty/whitespace-only after trimming; set a non-empty value or omit it to use the docker.io default" }}
{{- end }}
{{- if eq $repository "" }}
{{- fail "image.repository is empty/whitespace-only after trimming; set a non-empty value" }}
{{- end }}
{{- if regexMatch "\\s" $registry }}
{{- fail (printf "image.registry must not contain interior whitespace, got %q" $registry) }}
{{- end }}
{{- if regexMatch "\\s" $repository }}
{{- fail (printf "image.repository must not contain interior whitespace, got %q" $repository) }}
{{- end }}
{{/* Validate: digests in repository are not supported in map mode — use string form instead */}}
{{- if contains "@" $repository }}
{{- fail "image.repository must not contain a digest in map form — use a full image string (e.g. deployment.image: \"registry/repo@sha256:...\")" }}
{{- end }}
{{/*
Validate raw tag inputs *before* sprig `default` (below) swallows falsey values. Only falsy
non-string scalars (`tag: 0`, `tag: false`, `tag: []`) are rejected: those are silently
treated as unset by sprig `default` and would inherit appVersion / chart version, hiding the
user's typo. Truthy non-string scalars (e.g. unquoted YAML numbers like `tag: 5.6`) are
permitted because they are not swallowed and round-trip cleanly through toString. An empty
string is permitted because it is the documented "unset" sentinel.
Per-resource is checked only when an override is actually present so we don't double-report.
*/}}
{{- if and (kindIs "map" $image) (hasKey $image "tag") }}
{{- $resourceTag := get $image "tag" }}
{{- if and (ne (kindOf $resourceTag) "invalid") (not (kindIs "string" $resourceTag)) (not $resourceTag) }}
{{- fail (printf "image.tag (resource) is a falsey non-string value which would be silently treated as unset; got %s (value: %v). Quote the tag or remove it." (kindOf $resourceTag) $resourceTag) }}
{{- end }}
{{- end }}
{{- if hasKey $defaultImage "tag" }}
{{- $topTag := get $defaultImage "tag" }}
{{- if and (ne (kindOf $topTag) "invalid") (not (kindIs "string" $topTag)) (not $topTag) }}
{{- fail (printf "image.tag (top-level) is a falsey non-string value which would be silently treated as unset; got %s (value: %v). Quote the tag or remove it." (kindOf $topTag) $topTag) }}
{{- end }}
{{- end }}
{{- $tag := $effectiveImage.tag | default $defaultImage.tag | default $root.Values.appVersion | default "" }}
{{- $useChartVersionFallback := true }}
{{- if and (hasKey $root.Values "image") (kindIs "map" $root.Values.image) (hasKey $root.Values.image "useChartVersionAsTagFallback") }}
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
{{- fail (printf "image.useChartVersionAsTagFallback must be a bool or string ('true'/'false'), got %s (value: %v)" (kindOf $rawUseChartVersionFallback) $rawUseChartVersionFallback) }}
{{- end }}
{{- end }}
{{- if and (not $tag) $useChartVersionFallback }}
{{- $tag = ($root.Chart.Version | default "") }}
{{- end }}
{{- if and (not $tag) (not $useChartVersionFallback) }}
{{- fail (printf "image.tag and appVersion are both unset, and image.useChartVersionAsTagFallback is false. Chart rendering is blocked to prevent an untagged image reference (%s/%s), which is non-deterministic and unsafe. Set image.tag or appVersion explicitly, or set image.useChartVersionAsTagFallback to true." $registry $repository) }}
{{- end }}
{{/*
Normalize the resolved tag (mirrors registry/repository): coerce to string (truthy
non-string scalars like `tag: 5.6` are permitted upstream and need toString here),
then trim surrounding whitespace and reject interior whitespace. Without this,
`tag: " v1 "` produces broken YAML and `tag: "v 1"` renders an invalid OCI reference
(`registry/repo:v 1`) that K8s rejects far from the source of the typo.
*/}}
{{- if $tag }}
{{- $tagStr := trim (toString $tag) }}
{{- if eq $tagStr "" }}
{{- fail "image.tag is empty/whitespace-only after trimming; quote a non-empty tag or remove the field to use the fallback chain (appVersion / Chart.Version)" }}
{{- end }}
{{- if regexMatch "\\s" $tagStr }}
{{- fail (printf "image.tag must not contain interior whitespace, got %q" $tagStr) }}
{{- end }}
{{- $tag = $tagStr }}
{{- end }}
{{- $imageRef := printf "%s/%s" $registry $repository }}
{{- if $tag }}
{{- printf "%s:%s" $imageRef $tag }}
{{- else }}
{{- $imageRef }}
{{- end }}
{{- else }}
{{- fail "chart.imageReference: could not resolve image — set image.repository at the top level or per resource" }}
{{- end }}
{{- end -}}
{{- end -}}
