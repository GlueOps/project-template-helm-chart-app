{{/*
Shared Job spec template used by both Job and CronJob resources.

Renders the Job-level spec fields (everything inside `spec:` for a Job,
or inside `jobTemplate.spec:` for a CronJob) and the pod template.

Expected context dict keys:
  .job        - per-job values from the jobs map entry
  .globalSpec - global override values ($.Values.job or $.Values.cronJob)
  .resourceType - "job" or "cronJob"
  .name       - job name suffix
  .Chart      - $.Chart
  .Root       - $ (root context)

WARNING: CronJob `spec.suspend` and Job `spec.suspend` have different semantics.
CronJob suspend pauses scheduling of NEW jobs; Job suspend pauses an already-created
job's pod execution. CronJob renders its own suspend at the CronJob spec level, so
this helper only emits suspend for Job resources to avoid confusion.

WARNING: If activeDeadlineSeconds is set, Kubernetes will terminate the Job when
the deadline expires, even if backoffLimit retries remain. These two fields interact
and users should understand the implications of setting both.
*/}}
{{- define "chart.jobSpec" -}}
{{- if ne .resourceType "cronJob" }}
suspend: {{ .job.suspend | default false }}
{{- end }}
{{- if .globalSpec.parallelism }}
parallelism: {{ .globalSpec.parallelism }}
{{- else if .job.parallelism }}
parallelism: {{ .job.parallelism }}
{{- end }}
{{- if .globalSpec.completions }}
completions: {{ .globalSpec.completions }}
{{- else if .job.completions }}
completions: {{ .job.completions }}
{{- end }}
{{- if .globalSpec.backoffLimit }}
backoffLimit: {{ .globalSpec.backoffLimit }}
{{- else if .job.backoffLimit }}
backoffLimit: {{ .job.backoffLimit }}
{{- end }}
{{- if .globalSpec.activeDeadlineSeconds }}
activeDeadlineSeconds: {{ .globalSpec.activeDeadlineSeconds }}
{{- else if .job.activeDeadlineSeconds }}
activeDeadlineSeconds: {{ .job.activeDeadlineSeconds }}
{{- end }}
{{- if .globalSpec.ttlSecondsAfterFinished }}
ttlSecondsAfterFinished: {{ .globalSpec.ttlSecondsAfterFinished }}
{{- else if .job.ttlSecondsAfterFinished }}
ttlSecondsAfterFinished: {{ .job.ttlSecondsAfterFinished }}
{{- end }}
{{- if .globalSpec.podFailurePolicy }}
podFailurePolicy:
  {{- toYaml .globalSpec.podFailurePolicy | nindent 2 }}
{{- else if .job.podFailurePolicy }}
podFailurePolicy:
  {{- toYaml .job.podFailurePolicy | nindent 2 }}
{{- end }}
{{- $context := merge (dict "resourceType" .resourceType "name" .name "Chart" .Chart "Root" .Root) .job }}
template:
{{- include "chart.podTemplate" $context | nindent 2 }}
{{- end -}}
