# AI Agent Guide — project-template-helm-chart-app

A GlueOps Helm chart for deploying applications to Kubernetes. Supports Deployments, StatefulSets, Jobs, CronJobs, Services, Ingress, PDBs, PVCs, ExternalSecrets, KEDA, and custom resources.

## Quick Reference

```bash
helm lint .              # Lint the chart
helm unittest .          # Run unit tests
make test                # Full CI validation pipeline
```

## Detailed Documentation

- [Project Structure](.ai/structure.md)
- [Architecture Patterns](.ai/patterns.md)
- [Testing](.ai/testing.md)
- [Gotchas](.ai/gotchas.md)

## Conventions

- **Indentation**: 2 spaces in all YAML and templates
- **Template whitespace**: Use `{{-` and `-}}` for whitespace control
- **Values documentation**: All fields documented with `# --` comments in `values.yaml` (used by helm-docs)
- **Test files**: `tests/<resource>_test.yaml`, suite name matches resource
