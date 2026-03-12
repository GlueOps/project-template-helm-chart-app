# Architecture Patterns

## Shared Helpers (`_helpers.tpl`)

- **`chart.jobSpec`** — Data-driven helper rendering JobSpec fields for both Job and CronJob. Uses `$intFields`, `$stringFields`, and `$objectFields` lists. To add a new K8s JobSpec field, append to the appropriate list.
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
