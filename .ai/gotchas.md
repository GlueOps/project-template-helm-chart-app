# Gotchas

1. **`chart.renderLabels` handles annotations too** — The name says "labels" but it's used for both labels and annotations in job.yaml, cronjob.yaml, and _podTemplate.tpl. Both are key-value pairs so it works.

2. **`startingDeadlineSeconds` defaults to 30** — This is hardcoded in cronjob.yaml, NOT the K8s default (which is unbounded). This is intentional.

3. **`appLabels` vs `commonLabels`** — `appLabels` is for selectors (`matchLabels`), `commonLabels` is for metadata. Job and CronJob use `commonLabels` for metadata. Don't use `appLabels` for metadata — it's missing fields like `helm.sh/chart`.

4. **Empty extension helpers** — `chart.deploymentLabels` and `chart.deploymentAnnotations` in `_helpers.tpl` are intentionally empty. They're override points for users. Don't delete them.

5. **`merge` arg order matters** — First arg is destination (mutated), subsequent args are sources (read-only). When merging into root context `$` inside a range loop, always `deepCopy` the destination to prevent cross-iteration pollution.

6. **Job `suspend` is at spec level, not in `chart.jobSpec`** — The `suspend` field is rendered directly in job.yaml and cronjob.yaml templates, not through the shared helper.

7. **`ct lint` won't work locally** — It needs config files from the `helm/chart-testing-action` GitHub Action. Use `helm lint` locally instead.

8. **Example files are CI-validated** — Every file in `examples/*/values.yaml` gets run through the full validation pipeline in CI. Breaking an example breaks CI.
