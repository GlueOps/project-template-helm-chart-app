# app

![Version: 0.6.0](https://img.shields.io/badge/Version-0.6.0-informational?style=flat-square)

A Helm chart template for applications

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| appEnv | string | `"dev"` | Environment of the application |
| appName | string | `"example-app"` | Name of the application |
| appVersion | string | `"0.0.1"` | Version of the application |
| commonAnnotations | string | `nil` | Common annotations for all Kubernetes objects |
| commonLabels | string | `nil` | Common labels for all Kubernetes objects |
| configMap | object | `{"annotations":null,"configs":null,"enabled":false,"labels":null}` | ConfigMap configuration |
| configMap.annotations | string | `nil` | Annotations for the ConfigMap |
| configMap.configs | string | `nil` | Data for the ConfigMap |
| configMap.enabled | bool | `false` | Whether to create a ConfigMap |
| configMap.labels | string | `nil` | Labels for the ConfigMap |
| cronJob | object | `{"enabled":false,"jobs":null}` | CronJob configuration |
| cronJob.enabled | bool | `false` | Whether to create a CronJob |
| cronJob.jobs | string | `nil` | List of jobs to run |
| customResources | string | `nil` | CustomResources configuration |
| deployment | object | `{"affinity":{},"annotations":null,"containerPorts":null,"containerSecurityContext":null,"enabled":false,"envConfigMaps":null,"envMap":null,"envSecrets":null,"envVariables":null,"hostAliases":null,"initContainers":null,"labels":null,"lifecycle":null,"livenessProbe":null,"matchLabels":null,"nodeSelector":null,"readinessProbe":null,"replicas":1,"resources":{},"securityContext":null,"serviceAccount":{"enabled":false},"sidecar":null,"startupProbe":{},"strategy":"RollingUpdate","tolerations":null,"topologySpreadConstraints":null,"volumeMounts":null,"volumes":null}` | Deployment configuration |
| deployment.affinity | object | `{}` | Affinity rules for scheduling the pods |
| deployment.annotations | string | `nil` | Annotations for the Deployment |
| deployment.containerPorts | string | `nil` | Additional container ports |
| deployment.containerSecurityContext | string | `nil` | Security context for the container |
| deployment.enabled | bool | `false` | Whether to create a Deployment |
| deployment.envConfigMaps | string | `nil` | List of ConfigMap environment variables variable   - name of env variable inside container configMapName - name of kubernetes ConfigMap object configMapKey  - name of the key in ConfigMap object which holds the value |
| deployment.envMap | string | `nil` | Map of environment variables |
| deployment.envSecrets | string | `nil` | List of secret environment variables variable   - name of env variable inside container secretName - name of kubernetes secret object secretKey  - name of the key in secret object which holds the value |
| deployment.envVariables | string | `nil` | List of environment variables |
| deployment.hostAliases | string | `nil` | Host aliases for the pods |
| deployment.initContainers | string | `nil` | Init containers configuration |
| deployment.labels | string | `nil` | Labels for the Deployment |
| deployment.lifecycle | string | `nil` | Lifecycle hooks |
| deployment.livenessProbe | string | `nil` | Liveness probe configuration |
| deployment.matchLabels | string | `nil` | Match labels for the StatefulSet |
| deployment.nodeSelector | string | `nil` | Node selector for scheduling the pods |
| deployment.readinessProbe | string | `nil` | Readiness probe configuration |
| deployment.replicas | int | `1` | Number of replicas (ignored if .keda.enabled is true) |
| deployment.resources | object | `{}` | Resource requests and limits |
| deployment.securityContext | string | `nil` | Security context for the Deployment |
| deployment.serviceAccount | object | `{"enabled":false}` | Service account configuration |
| deployment.serviceAccount.enabled | bool | `false` | Whether to use the service account for deployment |
| deployment.sidecar | string | `nil` | Sidecar containers configuration |
| deployment.startupProbe | object | `{}` | Startup probe configuration |
| deployment.strategy | string | `"RollingUpdate"` | Deployment strategy |
| deployment.tolerations | string | `nil` | Tolerations for scheduling the pods |
| deployment.topologySpreadConstraints | string | `nil` | Topology spread constraints for scheduling the pods |
| deployment.volumeMounts | string | `nil` | Volume mounts for the container |
| deployment.volumes | string | `nil` | Volumes for the pod |
| externalSecret | object | `{"enabled":false,"refreshInterval":"2s","secretStore":{"name":"vault-backend"},"secrets":null}` | External Secret configuration |
| externalSecret.enabled | bool | `false` | Whether to create an External Secret |
| externalSecret.refreshInterval | string | `"2s"` | RefreshInterval is the amount of time before the values reading again from the SecretStore provider |
| externalSecret.secretStore | object | `{"name":"vault-backend"}` | Global SecretStore for all ExternalSecrets |
| externalSecret.secrets | string | `nil` | Data for the External Secret |
| image | object | `{"args":null,"command":null,"port":8080,"registry":"docker.io","repository":"nginx","tag":"1.15.12@sha256:23b4dcdf0d34d4a129755fc6f52e1c6e23bb34ea011b315d87e193033bcd1b68"}` | Docker image configuration |
| image.args | string | `nil` | Arguments to pass to the command |
| image.command | string | `nil` | Command to run in the Docker container |
| image.port | int | `8080` | Port the application will listen on (>1024) |
| image.registry | string | `"docker.io"` | Docker registry |
| image.repository | string | `"nginx"` | Docker image repository |
| image.tag | string | `"1.15.12@sha256:23b4dcdf0d34d4a129755fc6f52e1c6e23bb34ea011b315d87e193033bcd1b68"` | Docker image tag |
| ingress | object | `{"annotations":null,"enabled":false,"entries":null}` | Ingress configuration |
| ingress.annotations | string | `nil` | Annotations for the Ingress |
| ingress.enabled | bool | `false` | Whether to create an Ingress |
| ingress.entries | string | `nil` | Entries for the Ingress |
| job | object | `{"enabled":false,"jobs":null}` | Job configuration |
| job.enabled | bool | `false` | Whether to create a Job |
| job.jobs | string | `nil` | List of jobs to run |
| keda | object | `{"enabled":false,"scaledObject":{"enabled":false,"spec":{"triggers":[],"triggersMap":{}}},"triggerAuthentication":null}` | Keda configuration |
| keda.enabled | bool | `false` | Whether to enable Keda |
| keda.scaledObject | object | `{"enabled":false,"spec":{"triggers":[],"triggersMap":{}}}` | ScaledObject's spec |
| keda.scaledObject.spec.triggersMap | object | `{}` | TriggersMap spec |
| keda.triggerAuthentication | string | `nil` | TriggerAuthentication spec |
| namespaceOverride | string | `nil` | Override the default namespace |
| persistentVolumeClaim | object | `{"annotations":null,"enabled":false,"labels":null}` | persistentVolumeClaim configuration |
| persistentVolumeClaim.annotations | string | `nil` | Annotations for the persistentVolumeClaim |
| persistentVolumeClaim.enabled | bool | `false` | Whether to create a persistentVolumeClaim |
| persistentVolumeClaim.labels | string | `nil` | Labels for the persistentVolumeClaim |
| podDisruptionBudget | object | `{"enabled":false,"minAvailable":1}` | Pod Disruption Budget configuration |
| podDisruptionBudget.enabled | bool | `false` | Whether to create a Pod Disruption Budget |
| podDisruptionBudget.minAvailable | int | `1` | Minimum number of pods that must be available |
| secret | object | `{"annotations":null,"enabled":false,"lables":null,"secrets":null}` | Secret configuration |
| secret.annotations | string | `nil` | Annotations for the Secret |
| secret.enabled | bool | `false` | Whether to create a Secret |
| secret.lables | string | `nil` | Labels for the Secret |
| secret.secrets | string | `nil` | Data for the Secret |
| service | object | `{"annotations":null,"enabled":false,"labels":null,"ports":null,"type":"ClusterIP"}` | Service configuration |
| service.annotations | string | `nil` | Annotations for the Service |
| service.enabled | bool | `false` | Whether to create a Service |
| service.labels | string | `nil` | Labels for the Service |
| service.ports | string | `nil` | Ports for the Service |
| service.type | string | `"ClusterIP"` | Type of the Service |
| serviceAccount | object | `{"annotations":null,"create":false,"labels":null}` | Service Account configuration |
| serviceAccount.annotations | string | `nil` | Annotations for the Service Account |
| serviceAccount.create | bool | `false` | Whether to create a Service Account |
| serviceAccount.labels | string | `nil` | Labels for the Service Account |
| statefulSet | object | `{"affinity":{},"annotations":null,"containerPorts":null,"containerSecurityContext":null,"enabled":false,"envConfigMaps":null,"envMap":null,"envSecrets":null,"envVariables":null,"hostAliases":null,"initContainers":null,"labels":null,"lifecycle":null,"livenessProbe":null,"matchLabels":null,"nodeSelector":null,"readinessProbe":null,"resources":{},"securityContext":null,"serviceAccount":{"enabled":false},"sidecar":null,"startupProbe":{},"tolerations":null,"topologySpreadConstraints":null,"updateStrategy":"RollingUpdate","volumeClaimTemplates":null,"volumeMounts":null,"volumes":null}` | StatefulSet configuration |
| statefulSet.affinity | object | `{}` | Affinity rules for scheduling the pods |
| statefulSet.annotations | string | `nil` | Annotations for the StatefulSet |
| statefulSet.containerPorts | string | `nil` | Additional container ports |
| statefulSet.containerSecurityContext | string | `nil` | Security context for the container |
| statefulSet.enabled | bool | `false` | Whether to create a StatefulSet |
| statefulSet.envConfigMaps | string | `nil` | List of ConfigMap environment variables variable   - name of env variable inside container configMapName - name of kubernetes ConfigMap object configMapKey  - name of the key in ConfigMap object which holds the value |
| statefulSet.envMap | string | `nil` | Map of environment variables |
| statefulSet.envSecrets | string | `nil` | List of secret environment variables variable   - name of env variable inside container secretName - name of kubernetes secret object secretKey  - name of the key in secret object which holds the value |
| statefulSet.envVariables | string | `nil` | List of environment variables |
| statefulSet.hostAliases | string | `nil` | Host aliases for the pods |
| statefulSet.initContainers | string | `nil` | Init containers configuration |
| statefulSet.labels | string | `nil` | Labels for the StatefulSet |
| statefulSet.lifecycle | string | `nil` | Lifecycle hooks |
| statefulSet.livenessProbe | string | `nil` | Liveness probe configuration |
| statefulSet.matchLabels | string | `nil` | Match labels for the StatefulSet |
| statefulSet.nodeSelector | string | `nil` | Node selector for scheduling the pods |
| statefulSet.readinessProbe | string | `nil` | Readiness probe configuration |
| statefulSet.resources | object | `{}` | Resource requests and limits |
| statefulSet.securityContext | string | `nil` | Security context for the StatefulSet |
| statefulSet.serviceAccount | object | `{"enabled":false}` | Service account configuration |
| statefulSet.serviceAccount.enabled | bool | `false` | Whether to use the service account for statefulset |
| statefulSet.sidecar | string | `nil` | Sidecar containers configuration |
| statefulSet.startupProbe | object | `{}` | Startup probe configuration |
| statefulSet.tolerations | string | `nil` | Tolerations for scheduling the pods |
| statefulSet.topologySpreadConstraints | string | `nil` | Topology spread constraints for scheduling the pods |
| statefulSet.updateStrategy | string | `"RollingUpdate"` | Update strategy for the StatefulSet |
| statefulSet.volumeClaimTemplates | string | `nil` | Volume claim templates for the StatefulSet |
| statefulSet.volumeMounts | string | `nil` | Volume mounts for the container |
| statefulSet.volumes | string | `nil` | Volumes for the pod |
| waf | object | `{"enabled":false,"entries":null}` | WAF configuration |
| waf.enabled | bool | `false` | Whether to create a WAF |
| waf.entries | string | `nil` | Entries for the WAFs. Each WAF can have multiple TLD's but will share the same certificate. Create multiple as you need. |
