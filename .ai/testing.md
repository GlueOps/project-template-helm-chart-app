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

`.github/workflows/test-helm-chart.yaml` runs against a real k3s cluster:
1. `make lint` — ct lint + helm lint
2. `make unittest` — helm-unittest
3. `make test` — for each example directory, runs: helm template, yamllint, kubeconform, kube-linter, kube-score, polaris, kubeval, kubectl dry-run (client + server)

## Test Conventions

- Test files: `tests/<resource>_test.yaml`
- Suite name matches the resource type
- Canonical tests for shared helpers (like `chart.jobSpec`) live in `job_test.yaml`
- CronJob tests cover CronJob-specific fields + one integration smoke test for the shared helper
- Use `documentSelector` (not `documentIndex`) for multi-document tests (multiple jobs/cronjobs). Go map iteration order is non-deterministic, so positional `documentIndex` is fragile.

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
