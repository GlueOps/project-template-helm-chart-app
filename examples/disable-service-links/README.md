# Disabling Service Environment Variable Injection

By default, Kubernetes automatically injects environment variables for all services in the same namespace into every pod. This means when you run `env` inside a pod, you might see environment variables from other services like:

```bash
REDIS_SERVICE_HOST=10.0.0.1
REDIS_SERVICE_PORT=6379
POSTGRES_SERVICE_HOST=10.0.0.2
POSTGRES_SERVICE_PORT=5432
OTHER_APP_SERVICE_HOST=10.0.0.3
OTHER_APP_SERVICE_PORT=8080
```

This can be a security concern and also clutters the environment with variables your application doesn't need.

## Solution

This Helm chart supports disabling automatic service environment variable injection by setting `enableServiceLinks: false` in the pod specification.

## Usage

### For Deployments

```yaml
deployment:
  enabled: true
  enableServiceLinks: false  # Prevents injection of service env vars
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  readinessProbe:
    httpGet:
      path: /
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10
  livenessProbe:
    httpGet:
      path: /
      port: 8080
    initialDelaySeconds: 15
    periodSeconds: 20

# Also recommended for production deployments
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

### For StatefulSets

```yaml
statefulSet:
  enabled: true
  enableServiceLinks: false  # Prevents injection of service env vars
  resources:
    requests:
      cpu: 100m
      memory: 128Mi
    limits:
      cpu: 500m
      memory: 512Mi
  readinessProbe:
    httpGet:
      path: /
      port: 8080
    initialDelaySeconds: 5
    periodSeconds: 10
  livenessProbe:
    httpGet:
      path: /
      port: 8080
    initialDelaySeconds: 15
    periodSeconds: 20
```

### For Jobs

```yaml
job:
  enabled: true
  jobs:
    my-job:
      enableServiceLinks: false  # Prevents injection of service env vars
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi
```

### For CronJobs

```yaml
cronJob:
  enabled: true
  jobs:
    my-cronjob:
      schedule: "0 2 * * *"
      enableServiceLinks: false  # Prevents injection of service env vars
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi
```

## Default Behavior

By default, `enableServiceLinks` is set to `true` in this chart for backward compatibility. This means:

- ✅ Existing deployments continue to work without changes
- ✅ Service discovery environment variables are injected by default  
- ⚠️ Pods can see environment variables from all services in the namespace

To improve security and reduce environment variable clutter, you can set `enableServiceLinks: false`:

- ✅ Your pods will only see environment variables you explicitly define
- ✅ No automatic injection of service discovery environment variables
- ✅ Cleaner environment namespace inside containers
- ✅ Better security isolation between services

## Service Discovery Alternatives

If you need service discovery, consider these alternatives:

1. **DNS-based discovery**: Use service names directly (e.g., `redis-service.default.svc.cluster.local`)
2. **Explicit environment variables**: Define only the services you need
3. **ConfigMaps/Secrets**: Store service endpoints in configuration
4. **Service mesh**: Use tools like Istio for advanced service discovery

## Example

See [examples/disable-service-links/values.yaml](./values.yaml) for a complete example configuration.

## Testing

After deploying with `enableServiceLinks: false`, you can verify it's working by:

1. Deploy your application
2. Exec into the pod: `kubectl exec -it <pod-name> -- bash`
3. Run `env | grep SERVICE` - you should see no automatic service environment variables
4. You should only see the environment variables you explicitly defined

To test the default behavior (`enableServiceLinks: true`):

1. Deploy without setting `enableServiceLinks` or with `enableServiceLinks: true`
2. Exec into the pod: `kubectl exec -it <pod-name> -- bash`  
3. Run `env | grep SERVICE` - you should see service environment variables for other services in the namespace
