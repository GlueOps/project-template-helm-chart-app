# Architecture Patterns

## Shared Helpers (`_helpers.tpl`)

- **`chart.jobSpec`** — Data-driven helper rendering JobSpec fields for both Job and CronJob. Uses `$intFields`, `$stringFields`, and `$objectFields` lists. To add a new K8s JobSpec field, append to the appropriate list.
- **`chart.imagePullSecretName`** — Resolves registry pull secret for pod templates. Precedence: per-job `cronJob.jobs.*` / `job.jobs.*` → workload `imagePullSecrets` (`deployment`/`statefulSet`/`cronJob`/`job`) → `image.pullSecrets`. Selection is `hasKey` + non-null at every level, so the levels behave uniformly: a set value wins even when empty, `""` opts out (no pull secret, lower levels ignored), `null`/absent inherits. Requires string secret names; guards `image` map access when `.Values.image` is null.
- **`chart.jobPodGlobals`** — `pick` allowlist for cronJob/job global → pod context merge. Scoped to `imagePullSecrets` only; broadening it changes pod rendering for existing tenants on upgrade and must be a deliberate, versioned change.
- **`chart.jobEntryEnabled`** — Validates `jobs.<name>.enabled` is boolean when set.
- **`chart.renderLabels`** — Dual-format helper supporting both map (`{key: val}`) and list (`[{key: k, value: v}]`) formats. Used for both labels AND annotations (name is misleading but intentional). Only map format is documented to users; list format exists for backwards compatibility.
- **`chart.commonLabels`** — Full metadata labels (includes `helm.sh/chart`, `app.kubernetes.io/managed-by`, etc.)
- **`chart.appLabels`** — Selector labels only (used in `matchLabels`). Never add mutable fields here.
- **`chart.deploymentLabels` / `chart.deploymentAnnotations`** — Empty extension points in `_helpers.tpl`. They exist so users can override them. Don't delete.

## Label Hierarchy (precedence: last wins)

1. `commonLabels` (chart-level)
2. Global resource labels (`job.labels`, `cronJob.labels`)
3. Per-job labels (`jobs.<name>.labels`)

## Configuration Override Pattern

Global values cascade to per-job values. Per-job overrides global:
```yaml
job:
  backoffLimit: 6        # global default
  jobs:
    my-job:
      backoffLimit: 2    # overrides global
```

A workload-global `cronJob.imagePullSecrets` / `job.imagePullSecrets` is merged into each job's pod context via `chart.jobPodGlobals` (allowlist scoped to `imagePullSecrets` only — not other pod fields, `labels`/`annotations`, or JobSpec). Set `cronJob.jobs.<name>.enabled: false` (boolean) to skip a job defined in shared values.

## Zero-Value Safety

Use `hasKey` (not bare `if`) for numeric fields where `0` is valid:
```
{{- if hasKey $job "backoffLimit" }}    # correct: allows 0
{{- if $job.backoffLimit }}             # wrong: treats 0 as false
```

## Context Mutation Prevention

In `range` loops, use `deepCopy` before `merge` to prevent data leaking between iterations:
```
{{- include "chart.commonLabels" (merge (deepCopy $) (dict "suffixName" $name)) | indent 4 }}
```
The second arg to `merge` (source) is NOT mutated — only the first arg (destination) is. So `$job` as a source arg is safe without deepCopy.

## Pod Template Routing

`_podTemplate.tpl` handles all workload types via the `resourceType` field in the context dict. Each type has different branching:
- **deployment/statefulSet**: uses `chart.serviceAccountName` helper
- **job**: `restartPolicy` defaults to `Never`, labels include `resource-type: job`
- **cronJob**: `restartPolicy` defaults to `OnFailure`, labels include `resource-type: cronjob`

## Job vs CronJob Paths

- Job fields: `spec.*` (e.g., `spec.backoffLimit`)
- CronJob fields: `spec.jobTemplate.spec.*` (e.g., `spec.jobTemplate.spec.backoffLimit`)

This affects both templates and test assertions.
