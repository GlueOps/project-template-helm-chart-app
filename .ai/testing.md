# Testing

## Commands

```bash
helm lint .              # Lint the chart
helm unittest .          # Run unit tests (helm-unittest plugin required)
make lint                # ct lint + helm lint
make unittest            # helm unittest
make test                # Full validation pipeline (requires tools below)
```

## CI Pipeline

`.github/workflows/ci_test.yaml` runs against a real k3s cluster:
1. `make lint` — ct lint + helm lint
2. `make unittest` — helm-unittest
3. `make test` — for each example directory, runs: helm template, yamllint, kubeconform, kube-linter, kube-score, polaris, kubeval, kubectl dry-run (client + server). `examples/test.sh` runs `examples/*/values.yaml` in a first loop (skipping `testcases/`) and then `examples/testcases/*.yaml` in a second loop.

## Test Conventions

- Test files: `tests/<resource>_test.yaml`
- Suite name matches the resource type
- Canonical tests for shared helpers (like `chart.jobSpec`) live in `job_test.yaml`
- CronJob tests cover CronJob-specific fields + one integration smoke test for the shared helper
- Pod template metadata tests live in each workload's test file (deployment, statefulset, job, cronjob): `helm.sh/chart` absent from `spec.template.metadata` but present on the top-level resource; `glueops.dev/chart: app` present on the pod template (alone when `commonAnnotations` is empty/falsy, alongside `commonAnnotations` and workload/per-job annotations otherwise) and absent from top-level metadata (also asserted on the Service); and a chart-version-independence pair — render with `chart.version` 0.0.1 and 99.0.0 (with `appVersion` pinned) and assert the exact same `spec.template.metadata`. Use this two-chart-version pattern for any change touching pod template metadata, and keep at least one assertion that pod-template annotations are non-empty.
- Use `documentSelector` (not `documentIndex`) for multi-document tests (multiple jobs/cronjobs). Go map iteration order is non-deterministic, so positional `documentIndex` is fragile.
- Raw-render canaries: helm-unittest and kubectl dry-run parse the rendered YAML, so a quoting regression (an unquoted ` #` truncating an arg, `yes` becoming `true`, HTML-escaped `&`) is invisible to them. `examples/test.sh` greps the raw `helm template` output for the `configmap/` and `args-quoting/` examples and fails loudly if either canary block never ran. When you add a template that quotes user-supplied scalars, add an example plus a canary in the same style.

## Local Validation Tools

To run the full `make test` pipeline locally, install:
- `yamllint` (apt or pip)
- `kubeconform` (GitHub releases)
- `kube-linter` (GitHub releases)
- `kube-score` (GitHub releases)
- `polaris` (GitHub releases)
- `kubeval` (GitHub releases)

Note: `ct lint` requires config files provided by the `helm/chart-testing-action` GitHub Action — it won't run locally without them.

## Example Values

`examples/` contains validated example configurations. CI runs the full linting pipeline against each one. Keep them valid when making changes.
