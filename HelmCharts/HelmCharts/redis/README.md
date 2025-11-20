# Redis Helm Deployment (Stateless for Caching)

This configuration uses the [Bitnami Redis Helm chart](https://artifacthub.io/packages/helm/bitnami/redis) to deploy Redis as a stateless cache.

## Chart Details

- **Architecture**: Standalone
- **Persistence**: Disabled (stateless)
- **Authentication**: Disabled (dev only)
- **Use Case**: In-memory cache (non-critical data)


#helm repo add bitnami https://charts.bitnami.com/bitnami
#helm repo update

#helm install redis bitnami/redis \
  -f ./helm-charts/redis/values.yaml \
  -n your-namespace

#helm upgrade redis bitnami/redis \
  -f ./helm-charts/redis/values.yaml \
  -n your-namespace

#helm uninstall redis -n your-namespace