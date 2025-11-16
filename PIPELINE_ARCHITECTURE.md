# Frontend API Pipeline Architecture

## Overview

The pipeline has been restructured to be **simple, maintainable, and reliable**. It uses a modular template approach with clear separation of concerns.

## Pipeline Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Trigger Event                             │
├─────────────────────────────────────────────────────────────┤
│  • Pull Request to: dev, qa, staging, main                 │
│  • OR Code merged to: dev, qa, staging, main               │
│  • Path filter: services/frontend-api/** or helm-charts/** │
└──────────────────────┬──────────────────────────────────────┘
                       │
            ┌──────────┴──────────┐
            │                     │
       Pull Request          Branch Merge
            │                     │
            ▼                     ▼
   ┌─────────────────┐   ┌──────────────────┐
   │ PR VALIDATION   │   │ BUILD & TEST     │
   │                 │   │                  │
   │ • Restore pkg   │   │ • Restore pkg    │
   │ • Build code    │   │ • Build code     │
   │ • Run tests     │   │ • Run tests      │
   │ • Validate      │   │ • Publish tests  │
   │   Docker build  │   └──────────────────┘
   └─────────────────┘            │
                                  ▼
                         ┌──────────────────┐
                         │ DOCKER BUILD     │
                         │                  │
                         │ • Build image    │
                         │ • Push to ACR    │
                         └──────────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         │                        │                        │
         ▼                        ▼                        ▼
    ┌────────────┐          ┌────────────┐          ┌────────────┐
    │  DEV HELM  │          │ QA HELM    │          │ STAGING    │
    │  DEPLOY    │          │ DEPLOY     │          │ HELM       │
    │            │          │            │          │ DEPLOY     │
    │ • No       │          │ • No       │          │ • No       │
    │   approval │          │   approval │          │   approval │
    └────────────┘          └────────────┘          └────────────┘
                                                            │
                                                            ▼
                                                    ┌────────────────┐
                                                    │ PROD HELM      │
                                                    │ DEPLOY         │
                                                    │                │
                                                    │ • REQUIRES     │
                                                    │   APPROVAL     │
                                                    │ • Manual gate  │
                                                    └────────────────┘
```

## Template Files

### 1. `pr-validation-template.yml`
**Runs:** When a Pull Request is created
**Purpose:** Validate code before it can be merged

**Jobs:**
- `ValidateDotNetService` - Builds and runs unit tests
- `ValidateDockerBuild` - Validates Dockerfile can build
- `PRValidationSummary` - Reports validation status

**Condition:** `eq(variables['Build.Reason'], 'PullRequest')`

---

### 2. `build-and-test.yml`
**Runs:** After code is merged to dev/qa/staging/main
**Purpose:** Full build and test of .NET service

**Stage:** `BuildAndTest`
**Job:** `BuildAndTest`

**Steps:**
- Install .NET 8 SDK
- Restore NuGet packages
- Build solution
- Run unit tests
- Publish test results

---

### 3. `docker-build-push.yml`
**Runs:** After build-and-test succeeds
**Purpose:** Build Docker image and push to ACR

**Stage:** `DockerBuildPush`
**Dependencies:** `dependsOn: BuildAndTest`

**Steps:**
- Build Docker image
- Push to Azure Container Registry (ACR)

---

### 4. `helm-deploy.yml`
**Runs:** After docker-build-push succeeds (once per environment)
**Purpose:** Deploy to AKS using Helm

**Stage:** `HelmDeploy`
**Dependencies:** `dependsOn: DockerBuildPush`

**Features:**
- Sets K8S connection based on environment
- Downloads secure Helm values (for non-dev envs)
- Applies approval gate for production (if `requiresApproval: true`)
- Upgrades Helm release

**Approval Gate (Prod only):**
- Job: `WaitForValidation` (manual approval)
- Deployment job waits for approval before proceeding

---

## Environment-Specific Behavior

| Environment | Auto-Deploy | Requires Approval | K8S Connection |
|---|---|---|---|
| dev | Yes | No | `aks-dev-connection` |
| qa | Yes | No | `aks-qa-connection` |
| staging | Yes | No | `aks-staging-connection` |
| prod | Yes | **YES** | `aks-prod-connection` |

---

## How It Works

### When a PR is Raised

1. ✅ Azure DevOps detects PR to protected branch
2. ✅ Triggers `pr-validation-template.yml`
3. ✅ PR Validation stage runs:
   - Builds code
   - Runs tests
   - Validates Docker build
4. ✅ Results shown in PR checks
5. ⏳ Developer can only merge if validation passes

### When Code is Merged

1. ✅ PR is merged to dev/qa/staging/main
2. ✅ Trigger fires for the branch
3. ✅ **BUILD AND TEST** stage runs
4. ✅ **DOCKER BUILD AND PUSH** stage runs (on success)
5. ✅ **HELM DEPLOY** stages run (once per environment)
   - Each environment deploys independently
   - Prod deployment pauses for manual approval

---

## Key Benefits

✅ **Simple & Clear** - Each template has one responsibility
✅ **No Complex Conditionals** - Conditions are minimal and explicit
✅ **Reliable** - Tested YAML syntax, no parsing errors
✅ **Scalable** - Easy to add new environments (just add another helm-deploy call)
✅ **Maintainable** - Each stage can be updated independently
✅ **Safe** - Production deployments require manual approval

---

## Service Connection References

Update these in `azure-pipeline.yml` lines 39, 82, 94, 106, 118:

- **acrServiceConnection**: Azure Container Registry connection name
  - Default: `my-acr-connection`
  - Update with your actual ACR connection name

- **k8sServiceConnection** (per environment): Kubernetes service connection
  - Dev: `aks-dev-connection`
  - QA: `aks-qa-connection`
  - Staging: `aks-staging-connection`
  - Prod: `aks-prod-connection`

---

## Troubleshooting

**PR Validation Not Running?**
- Check that `pr-validation-template.yml` condition is `eq(variables['Build.Reason'], 'PullRequest')`
- Ensure PR is targeting a protected branch (dev, qa, staging, main)
- Verify path filters match your changes

**Deployment Not Running?**
- Check branch name matches trigger branches
- Verify path includes `services/frontend-api/**` or `shared/helm-charts/**`
- Confirm all service connections are configured in Azure DevOps

**Approval Gate Not Showing?**
- Only shows for prod environment
- Requires `requiresApproval: true` in helm-deploy parameters
- Check Azure DevOps environment is configured

---

## Testing the Pipeline

1. **Test PR Validation:**
   ```
   git checkout -b feature/test-pr
   # Make a small change
   git push origin feature/test-pr
   # Create PR to dev
   # Watch PR validation run
   ```

2. **Test Deployment:**
   ```
   # After PR is merged to dev
   # Watch Build → Docker → Helm Deploy stages run
   ```

3. **Test Production Approval:**
   ```
   # Merge to main
   # Pipeline will pause at "Approval Gate - Production Deployment"
   # Approve in Azure DevOps
   # Deployment proceeds
   ```
