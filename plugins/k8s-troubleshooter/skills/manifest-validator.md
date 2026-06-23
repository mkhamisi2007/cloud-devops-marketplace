# Skill: manifest-validator

Validate Kubernetes manifests against CKA best practices for production readiness.

## Description

Validates Kubernetes Deployment manifests for resource management, health probes, image versioning, and RBAC following Certified Kubernetes Administrator standards.

## Input

**Type**: Kubernetes manifest (YAML or JSON)

**Accepted Formats**:
- Single Deployment resource
- Deployment with multiple containers
- StatefulSet or DaemonSet
- Multi-resource manifest (all resources analyzed)

**Example**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  replicas: 3
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
    spec:
      containers:
      - name: api
        image: myapi:1.0.0
```

**Validation**:
- Must be valid YAML or JSON
- Must contain at least one resource definition
- Must have `apiVersion` and `kind` fields

## Processing

### 1. Parse Manifest
Extract resource definitions and container specifications

### 2. Validate Four Rules

#### Rule 1: Resource Requests & Limits

**Requirement**: Every container must specify CPU and memory requests AND limits

**Why**: 
- Requests enable scheduler to place pods on appropriate nodes
- Limits prevent one pod from consuming all cluster resources
- Enables Kubernetes eviction policies for overcommitted nodes

**Violations**:
- Missing `resources.requests.cpu`
- Missing `resources.requests.memory`
- Missing `resources.limits.cpu`
- Missing `resources.limits.memory`
- Limits lower than requests

**Report Format**:
```
### Missing Resource Limits
**Severity**: HIGH
**Container**: api
**Current**: No resources defined
**Fix**: Add to container spec:
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "1000m"
    memory: "512Mi"
```

**Recommended Values**:
- Small app: 100m CPU, 128Mi memory (requests); 500m CPU, 256Mi (limits)
- Medium app: 250m CPU, 256Mi memory (requests); 1000m CPU, 512Mi (limits)
- Large app: 500m CPU, 512Mi memory (requests); 2000m CPU, 1Gi (limits)

---

#### Rule 2: Health Probes (Liveness & Readiness)

**Requirement**: Every Deployment must have BOTH liveness AND readiness probes

**Exceptions**: Job, CronJob (not long-running)

**Why**:
- **Liveness probe**: Kubernetes restarts unhealthy pods automatically
- **Readiness probe**: Kubernetes only sends traffic to ready pods
- Together enable self-healing and safe rolling updates

**Violations**:
- Missing `livenessProbe`
- Missing `readinessProbe`
- Probe timing too aggressive (low `initialDelaySeconds`)

**Report Format**:
```
### Missing Liveness Probe
**Severity**: HIGH
**Container**: api
**Current**: No livenessProbe defined
**Fix**: Add to container spec:
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

**Recommended Timing**:
- `initialDelaySeconds`: 15-30 (app startup time)
- `periodSeconds`: 10 (check every 10 seconds)
- `timeoutSeconds`: 5 (wait 5 seconds for response)
- `failureThreshold`: 3 (restart after 3 failures)

**Probe Types** (choose one):
- `httpGet`: For HTTP/HTTPS endpoints (recommended for web apps)
- `tcpSocket`: For TCP connections (databases, message queues)
- `exec`: For shell commands (custom health checks)

---

#### Rule 3: Image Versioning

**Requirement**: All images must use specific version tags (never "latest")

**Why**:
- "latest" changes at unpredictable times
- Makes deployments non-deterministic
- Can cause silent breaking changes

**Violations**:
- Image uses "latest" tag
- Image has no tag at all
- Image uses broad tags (v1, v1.0)

**Report Format**:
```
### Image Uses "latest" Tag
**Severity**: MEDIUM
**Container**: api
**Current**: image: myapi:latest
**Fix**: Use specific version:
image: myapi:1.0.0
```

**Recommended Tag Formats**:
- Semantic versioning: `myapp:1.0.0`, `myapp:1.2.3`
- Git SHA: `myapp:abc1234` (for git-based builds)
- Timestamp: `myapp:2024-01-15-154320` (for date-based builds)
- Never: `latest`, `main`, `develop`, `v1`, `v1.0`

---

#### Rule 4: RBAC (Role-Based Access Control)

**Requirement**: Service accounts must follow principle of least privilege

**Violations**:
- `serviceAccountName` points to cluster-admin role
- Service account has wildcard permissions (`*`)
- Service account can modify or delete other resources

**Report Format**:
```
### Overly Permissive Service Account
**Severity**: CRITICAL
**Current**: serviceAccountName: admin
**Risk**: Pod has cluster-admin role; any compromise affects entire cluster
**Fix**: Create minimal role with only required permissions:
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: api-minimal
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get"]
```

## Output

**Format**: Markdown validation report

**Exit Code**:
- `0` = All checks pass (production ready)
- `1` = Violations found (fix before deploying)

### Example Output (All Pass)

```markdown
# Kubernetes Manifest Validation Report

**Resource**: apps/v1/Deployment[api-server]

## ✅ All Checks Pass

This manifest follows CKA best practices and is production-ready:
- ✅ Resource requests and limits defined on all containers
- ✅ Liveness and readiness probes configured
- ✅ Images use specific version tags
- ✅ Service account follows least privilege principle

### Summary
- Containers: 1
- Violations: 0
- Ready for production deployment
```

### Example Output (Violations Found)

```markdown
# Kubernetes Manifest Validation Report

**Resource**: apps/v1/Deployment[api-server]

## ❌ Violations Found (3)

### HIGH: Missing Resource Limits
**Container**: api
**Current**: No resources defined
**Impact**: Pod can consume unlimited CPU/memory; may starve other pods

**Fix**: Add to container spec:
```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "256Mi"
```

### HIGH: Missing Liveness Probe
**Container**: api
**Current**: No livenessProbe defined
**Impact**: Failed pods won't restart automatically; service degradation

**Fix**: Add to container spec:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
```

### MEDIUM: Image Uses "latest" Tag
**Container**: api
**Current**: image: api:latest
**Impact**: Deployments are non-deterministic; can break on image rebuild

**Fix**: Use specific version:
```yaml
image: api:1.0.0
```

## Summary
- Resource: Deployment[api-server]
- Containers: 1
- Violations: 3 (2 HIGH, 1 MEDIUM)
- Recommendation: Fix HIGH violations before production deployment

## Priority Fixes
1. **Add resource limits** - Prevents resource starvation
2. **Add health probes** - Enables self-healing
3. **Use specific image tag** - Ensures deterministic deployments
```

## Error Handling

| Error | Cause | Recovery |
|-------|-------|----------|
| "Invalid YAML/JSON" | Syntax error in manifest | Fix indentation/formatting; validate with `kubectl apply --dry-run=client` |
| "No resources found" | Empty input | Provide valid Kubernetes manifest |
| "Unsupported resource type" | CRD or custom resource | Focus on standard types: Deployment, StatefulSet, DaemonSet |
| "Missing required fields" | Manifest incomplete | Ensure `apiVersion`, `kind`, `metadata` are present |

## Related Checks

**Pre-deployment**: Run this skill before `kubectl apply`
```bash
/plugin run k8s-troubleshooter manifest-validator
# Provide your manifest, fix violations, then apply
kubectl apply -f deployment.yaml
```

**Post-deployment**: Use agent for live cluster diagnosis
```bash
kubectl describe pods
# Copy output to k8s-diagnosis agent
/plugin run k8s-troubleshooter k8s-diagnosis
```

## Standards Reference

This skill enforces:

**CKA Best Practices**:
- Resource requests/limits for scheduler efficiency
- Health probes for reliability and self-healing
- Service account principle of least privilege

**Kubernetes Best Practices**:
- Image pinning (specific versions, no "latest")
- Declarative configuration (manifests)
- Separation of concerns (one deployment per responsibility)

## Assumptions

- Kubernetes 1.20+ (modern probe configuration)
- Deployment/StatefulSet/DaemonSet as primary resources
- Standard Kubernetes RBAC (no custom policies)
- Manifest represents single app/service

## Performance Target

Validate typical Deployment manifest in <5 seconds
