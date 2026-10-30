# Gotchas

1. **`chart.renderLabels` handles annotations too** — The name says "labels" but it's used for both labels and annotations in job.yaml, cronjob.yaml, and _podTemplate.tpl. Both are key-value pairs so it works.

2. **`startingDeadlineSeconds` defaults to 30** — This is hardcoded in cronjob.yaml, NOT the K8s default (which is unbounded). This is intentional.

3. **`appLabels` vs `commonLabels`** — `appLabels` is for selectors (`matchLabels`), `commonLabels` is for metadata. Job and CronJob use `commonLabels` for metadata. Don't use `appLabels` for metadata — it's missing fields like `app.kubernetes.io/managed-by`. Pod templates use `podTemplateLabels` / `podTemplateAnnotations`, not the common helpers (see 9, 11).

4. **Empty extension helpers** — `chart.deploymentLabels` and `chart.deploymentAnnotations` in `_helpers.tpl` are intentionally empty. They're override points for users. Don't delete them.

5. **`merge` arg order matters** — First arg is destination (mutated), subsequent args are sources (read-only). When merging into root context `$` inside a range loop, always `deepCopy` the destination to prevent cross-iteration pollution.

6. **Job `suspend` is at spec level, not in `chart.jobSpec`** — The `suspend` field is rendered directly in job.yaml and cronjob.yaml templates, not through the shared helper.

7. **`ct lint` won't work locally** — It needs config files from the `helm/chart-testing-action` GitHub Action. Use `helm lint` locally instead.

8. **Example files are CI-validated** — Every file in `examples/*/values.yaml` gets run through the full validation pipeline in CI. Breaking an example breaks CI.

9. **No `helm.sh/chart` on pod templates** — `helm.sh/chart` (`<chart>-<version>`) changes on every release. On a pod template it rolls every Deployment/StatefulSet on each chart bump and makes `helm upgrade` fail with `spec.template: field is immutable` for Jobs still in the cluster. `_podTemplate.tpl` therefore uses `chart.podTemplateLabels` / `chart.podTemplateAnnotations`, which never emit it. Top-level resources keep it via `chart.commonLabels` / `chart.commonAnnotations`. Never put any chart-version-derived value in pod-template metadata.

11. **Pod-template annotations must never be empty** — `chart.podTemplateAnnotations` always emits the constant `glueops.dev/chart: <.Chart.Name>`. With an empty map, Argo CD's default client-side diff shows externally-added pod annotations (`kubectl rollout restart`, Argo CD "Restart", Stakater Reloader) as perpetual OutOfSync. It is skipped when `.Values.commonAnnotations` sets the same key (user value wins, no duplicate key). Changing its value (or removing it) rolls every workload and breaks existing Jobs, like any pod-template change.

12. **Other `.Chart.Version` leaks into the pod template** — `app.version` falls back to `.Chart.Version` when `appVersion` is empty, and that value lands in `app.kubernetes.io/version` on the pod template *and* in `matchLabels` (immutable selector). The image tag chain (`image.tag` → `appVersion` → `.Chart.Version` when `useChartVersionAsTagFallback`) does the same for the container image. So chart bumps are only pod-neutral while `appVersion` is non-empty (default `"0.0.1"`) or image tags are set; don't change the `appVersion` default or fallbacks casually.

13. **Container `command`/`args` items are JSON-quoted** — `_podTemplate.tpl` renders them through `chart.containerStringList` (`toString | toRawJson`; null/map/list items fail closed). Never go back to a bare `- {{ . }}`: YAML retyped the item (`a: b` → map, ` #` → truncated, `yes`/`8080` → bool/int, leading `*`/`&`/`[` or a block scalar → render error). helm-unittest and `kubectl --dry-run=client` parse the YAML first and cannot see those regressions, so `examples/args-quoting/` plus the raw-render greps in `examples/test.sh` are the guard; keep the two in sync. Changing the quoting again changes every pod template that sets command/args (see 9). Residual: DEL (0x7F) and C1 control characters in an item still fail the render with go-yaml's `control characters are not allowed` (toRawJson leaves them raw; 0.17.x failed the same way).
