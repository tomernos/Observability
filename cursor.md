# Agent Separation Definitions

## Golden Path Definition

The AWS golden path is complete when: Terraform in `Observability/infra-tf/` provisions EKS with Karpenter using remote S3 state; ChatApplication deploys via Helm with correct image tags wired through values files; a Jenkins pipeline in `ChatApplication/Jenkins/` uses shared libraries to build→push to ECR→terraform apply→helm upgrade→smoke test; and the cluster is healthy and the app is reachable. This path must be reproducible and documented with zero secrets in repo.

## Agents

### 1. REPO-ORCHESTRATOR (lead)
- Owns plan, sequencing, scope control, acceptance criteria
- Decides what gets changed and in what order
- Coordinates handoffs between agents

### 2. INFRA-TF AGENT
- Scope: `Observability/infra-tf/**`
- Tasks:
  - Validate `backend.tf` points to S3 remote state
  - List resources in `main.tf`
  - Document required vars (no defaults)
  - Document outputs
  - Provide `terraform init/plan/apply` commands
  - Identify blockers for `terraform apply`
- Rule: No redesign; only minimal edits needed to make `terraform plan/apply` succeed and be readable

### 3. APP-DEPLOY AGENT
- Scope: `ChatApplication/**` plus Helm chart folders
- Tasks:
  - Identify Helm chart entrypoint
  - Document values files and image repo/tag wiring
  - Document k8s manifests usage
  - Define smoke test endpoint
  - List required k8s resources
- Rule: Freeze app logic; only deployment/config changes

### 4. CI/CD (JENKINS) AGENT
- Scope: `ChatApplication/Jenkins/**` and `JenkinsSharedLibrary/**`
- Tasks:
  - Determine if Jenkinsfile exists and runs
  - List working shared lib vars steps and required inputs
  - Generate first working pipeline: build→ECR push→terraform apply→helm upgrade→smoke test
- Rule: No "maybe"; mark missing vs broken; keep pipeline minimal and working

### 5. OBSERVABILITY AGENT
- Scope: `Observability/grafana-tf/**` and `Observability/**` (excluding `infra-tf`)
- Tasks:
  - Confirm current metrics/logs wiring
  - Define one minimal alert path later (not now)
- Rule: Do not expand scope into tracing yet

### 6. SECURITY/COMPLIANCE AGENT (lightweight)
- Scope: Review-only across `infra-tf` and Jenkins
- Tasks:
  - Ensure no secrets in repo
  - Verify tfstate not committed
  - Document IAM least privilege notes
  - Document SSM over SSH notes
- Rule: Only block issues; no big policy work yet

## Hard Constraints

- No Python→Node rewrite
- No Azure; single AWS path first
- No multi-runtime until first pipeline works
- Keep under control; small commits
- Docs only when needed
- No functional changes unless required for plan/apply to succeed

## Handoff Protocol

Each agent outputs ONLY:
- (a) Files to change/create
- (b) Exact commands to validate
- (c) Top blockers

## File Boundaries

- **REPO-ORCHESTRATOR**: All repos (coordination only, no direct edits)
- **INFRA-TF AGENT**: `Observability/infra-tf/**` only
- **APP-DEPLOY AGENT**: `ChatApplication/**` and `ChatApplication/helm-chart/**` only
- **CI/CD (JENKINS) AGENT**: `ChatApplication/Jenkins/**` and `JenkinsSharedLibrary/**` only
- **OBSERVABILITY AGENT**: `Observability/grafana-tf/**` and `Observability/**` excluding `Observability/infra-tf/**`
- **SECURITY/COMPLIANCE AGENT**: Read-only access to `Observability/infra-tf/**` and `ChatApplication/Jenkins/**`

---

## Step-by-Step Execution Plan

### Phase 0: Bootstrap State (COMPLETED ✅)
- ✅ Bootstrap scripts created: `Observability/infra-tf/scripts/bootstrap-state.sh` and `.ps1`
- ✅ Scripts create S3 bucket and DynamoDB table with permission prompts
- **Status**: Scripts ready, user must execute manually

### Phase 1: Infrastructure Validation (NEXT - INFRA-TF AGENT)
**Agent**: INFRA-TF AGENT
**Status**: Ready to execute
**Tasks**:
1. Verify backend.tf configuration (S3 + DynamoDB)
2. Run terraform validation script
3. Document any blockers
4. Ensure cluster_name output exists

**Expected Output**:
- Terraform init succeeds
- Terraform validate passes
- Terraform plan shows resources to create
- No blockers for terraform apply

### Phase 2: Application Deployment Config (NEXT - APP-DEPLOY AGENT)
**Agent**: APP-DEPLOY AGENT
**Status**: Ready to execute
**Tasks**:
1. Verify Helm chart image paths (ECR format)
2. Document smoke test endpoint
3. Verify values files structure
4. List required k8s resources

**Expected Output**:
- Helm chart uses ECR image paths
- Smoke test endpoint documented
- Values files properly structured
- No blockers for helm deploy

### Phase 3: Pipeline Readiness (NEXT - CI/CD AGENT)
**Agent**: CI/CD (JENKINS) AGENT
**Status**: Ready to execute
**Tasks**:
1. Verify Jenkinsfile syntax and logic
2. Verify shared library functions exist
3. Document required Jenkins credentials
4. Create validation checklist

**Expected Output**:
- Jenkinsfile is valid
- All shared lib functions available
- Credentials documented
- Pipeline ready to run

### Phase 4: First Pipeline Run (MANUAL)
**Action**: User triggers Jenkins pipeline
**Prerequisites**: Phases 1-3 complete
**Validation**: Deployment validation script

### Phase 5: Observability Baseline (FUTURE - OBSERVABILITY AGENT)
**Agent**: OBSERVABILITY AGENT
**Status**: After golden path works
**Tasks**: TBD

### Phase 6: Security Review (FUTURE - SECURITY AGENT)
**Agent**: SECURITY/COMPLIANCE AGENT
**Status**: After golden path works
**Tasks**: TBD

---

## Current Execution Status

**Completed**:
- ✅ Bootstrap scripts created
- ✅ Validation scripts created
- ✅ Jenkinsfile updated with ECR push, terraform apply, helm deploy
- ✅ Deployment validation scripts created

**Next Steps** (In Order):
1. **INFRA-TF AGENT** → Validate Terraform configuration
2. **APP-DEPLOY AGENT** → Verify Helm chart configuration
3. **CI/CD AGENT** → Verify pipeline readiness

**Blockers**: None identified yet (agents will report)

---

## Agent Execution Prompts

See section below for specific prompts to give each agent.

