# Project Structure

```
templates/
  _helpers.tpl          # Shared helpers (labels, annotations, jobSpec, renderLabels)
  _podTemplate.tpl      # Shared pod template used by Deployment, StatefulSet, Job, CronJob
  deployment.yaml       # Deployment resource
  statefulset.yaml      # StatefulSet resource
  job.yaml              # Job resource (batch/v1)
  cronjob.yaml          # CronJob resource (batch/v1)
  service.yaml          # Service
  ingress.yaml          # Ingress
  ...
tests/                  # helm-unittest test files (*_test.yaml)
examples/               # Example values files + validation scripts
values.yaml             # Default values with inline documentation
```

## Key Files

- **`values.yaml`** — All fields documented with `# --` comments (used by helm-docs to auto-generate docs)
- **`templates/_helpers.tpl`** — All shared template helpers. New helpers go here.
- **`templates/_podTemplate.tpl`** — Shared pod spec for all workload types. Receives a context dict with `resourceType`, `name`, `Chart`, `Root`, plus per-resource config.
- **`examples/test.sh`** — Runs the full validation pipeline (yamllint, kubeconform, kube-linter, kube-score, polaris, kubeval, kubectl dry-run) against each example directory.
- **`.github/workflows/test-helm-chart.yaml`** — CI pipeline: lint, unittest, full validation against a real k3s cluster.
