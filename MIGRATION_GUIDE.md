# Service Migration Guide: Old → New Pipeline Structure


## Example: Migrate Chats (from old sample) to the new structure

1) Create the service folder and copy files from frontend-api
```bash
copy the chats service to services directory
cp services/frontend-api/azure-pipeline.yml services/chats/azure-pipeline.yml
cp services/frontend-api/values.yaml services/chats/values.yaml
cp services/frontend-api/nuget.config services/chats/nuget.config
```

2) Edit services/chats/azure-pipeline.yml (5 fields + 2 path blocks)
- Variables section:
  - solutionName: 'Chats'
  - pathToSolutionFolder: 'services/chats'
  - buildContext: 'services/chats'
  - releaseName: 'chatsmicroservice'
  - acrUrl: '<your-acr>.azurecr.io' (keep or update)
- PR/trigger paths: change all occurrences of `services/frontend-api/**` → `services/chats/**`
- Prod stage: set `secureYml: 'mycai-chats-prod-secrets.yml'`
- Service connections: update to your real names
  - acrServiceConnection: '<your-acr-connection>'
  - k8sServiceConnection (dev/qa/staging/prod): '<your-aks-connection>'

3) Edit services/chats/values.yaml (optional tweaks)
- Update image.repository if you keep per-service repos (else Helm override will set it)
- Adjust env, resources, ports as needed for Chats

4) Upload prod secure values file (once)
- Azure DevOps → Pipelines → Library → Secure files → Upload `mycai-chats-prod-secrets.yml`

5) Create the pipeline in Azure DevOps
- Pipelines → New Pipeline → Existing YAML → `services/chats/azure-pipeline.yml`

## Notes (parity with old structure)
- NuGet auth is already in templates; no extra steps required.
- Secure files are downloaded at deploy time when `secureYml` is set.
- Helm chart is shared at `shared/helm-charts/plain-app-chart`.