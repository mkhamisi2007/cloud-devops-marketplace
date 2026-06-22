# Contract: k8s-troubleshooter Plugin

**Plugin**: k8s-troubleshooter  
**Version**: 1.0.0  
**Date**: 2026-06-22

## Overview

The k8s-troubleshooter plugin provides an agent for interactive pod failure diagnosis and a skill for manifest validation. Both analyze Kubernetes configurations and outputs to identify issues and suggest remediation.

---

## Agent Contract: `k8s-diagnosis`

### Input

**Type**: kubectl output (text)  
**Format**: Raw output from kubectl commands  
**Examples**:
- `kubectl describe pods --all-namespaces`
- `kubectl get events`
- `kubectl logs <pod-name>`
- Combined output pasted as text

**Validation**:
- Input must contain recognizable Kubernetes output (pods, events, or logs)
- May be truncated or incomplete; agent provides best-guess diagnosis

### Processing

The agent analyzes Kubernetes output to diagnose pod failures:

**Failure States Diagnosed**:

1. **CrashLoopBackOff**
   - Likely causes: Startup checks failing, health probes too strict, environment/config missing
   - Diagnostic questions: What error appears in logs? Are env vars set? Are probes configured?
   - Remediation: Adjust liveness probe timing, fix env config, review startup logs

2. **Pending**
   - Likely causes: Resource shortage, node affinity constraints, PVC not bound, image pull errors
   - Diagnostic questions: Are resources available? Do node labels match selectors? Is PVC in Bound state?
   - Remediation: Increase cluster resources, adjust node selectors, ensure PVC available

3. **OOMKilled (Out of Memory)**
   - Likely causes: Memory limit too low, memory leak in application
   - Diagnostic questions: What is current memory usage vs. limit? Is memory usage growing?
   - Remediation: Increase memory limit, investigate memory leak in app

4. **ImagePullBackOff**
   - Likely causes: Image not found, wrong image tag, registry authentication
   - Diagnostic questions: Does image exist? Is tag correct? Are registry credentials available?
   - Remediation: Fix image name/tag, add image pull secrets

### Output

**Format**: Markdown diagnostic report  
**Structure**:
```
## Pod Diagnosis Report

### Summary
[Overview of pods analyzed and issues found]

### Pod: [namespace/pod-name]
**State**: [CrashLoopBackOff | Pending | OOMKilled | etc.]
**Likely Cause**: [Root cause hypothesis]
**Evidence**: [Quotes from logs/events]
**Remediation Steps**:
1. [Action 1]
2. [Action 2]
...

### Pod: [next-pod]
...

### General Recommendations
- [Cross-cutting fix if multiple pods have same issue]
```

**Example Output**:
```
## Pod Diagnosis Report

### Summary
Analyzed 3 pods in production namespace:
- 2 pods in CrashLoopBackOff (liveness probe failures)
- 1 pod in Pending (insufficient memory)

### Pod: production/api-server-1
**State**: CrashLoopBackOff
**Likely Cause**: Liveness probe failing on startup
**Evidence**: Logs show "Connection refused on port 8080" after 5 seconds
**Remediation Steps**:
1. Increase initialDelaySeconds to 15 (allow app startup time)
2. Review application startup logs to verify port 8080 is listening
3. Test locally: `docker run -p 8080:8080 api-server:1.0.0`

### Pod: production/worker-2
**State**: Pending
**Likely Cause**: Insufficient memory in cluster
**Evidence**: Events show "Insufficient memory" for 10 minutes
**Remediation Steps**:
1. Check current memory usage: `kubectl top nodes`
2. Scale up cluster or remove non-critical pods
3. Reduce worker memory request from 2Gi to 1Gi if safe

### General Recommendations
- Add readiness probes with short initialDelaySeconds to avoid CrashLoopBackOff cascades
- Set resource requests to realistic limits based on monitoring data
```

---

## Skill Contract: `manifest-validator`

### Input

**Type**: Kubernetes manifest (YAML or JSON)  
**Format**: Single Deployment or list of resources  
**Example**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  template:
    spec:
      containers:
      - name: api
        image: api:1.0.0
```

**Validation**:
- Must be valid YAML/JSON
- Must contain at least one Kubernetes resource definition
- Must have apiVersion and kind fields

### Processing

The skill validates Kubernetes manifests against CKA best practices:

**Rules Enforced**:

1. **Resource Requests & Limits (CKA Best Practice)**
   - Rule: Every container must have `requests.cpu`, `requests.memory`, `limits.cpu`, `limits.memory`
   - Rationale: Prevents resource starvation; enables pod eviction policies
   - Violation: Missing requests or limits
   - Fix: Add resource block to container spec

2. **Health Probes (CKA Best Practice)**
   - Rule: Every Deployment must have liveness AND readiness probes
   - Exception: Job/CronJob resources exempt (no long-running pods)
   - Rationale: Enables Kubernetes to restart failed pods and route traffic only to ready pods
   - Violation: Missing probe configuration
   - Fix: Add livenessProbe and readinessProbe to container spec

3. **Image Versioning (Security)**
   - Rule: Images must use specific version tags (never "latest")
   - Exception: CI/CD builds may use short-lived tags
   - Rationale: Ensures deterministic deployments; prevents breaking changes
   - Violation: Image uses "latest" or no tag
   - Fix: Specify exact image version (e.g., "api:1.0.0-sha256-abc123")

4. **RBAC (Security - CKA Best Practice)**
   - Rule: Deployments must not use serviceAccountName pointing to cluster-admin role
   - Rationale: Principle of least privilege; prevents container from having cluster-level access
   - Violation: ServiceAccount with cluster-admin binding
   - Fix: Create minimal role with only required permissions

### Output

**Format**: Markdown report  
**Exit Code**:
- `0`: All checks pass
- `1`: Violations found (manifest not recommended for production)

**Example Output** (violations):
```
# Kubernetes Manifest Validation Report

**Resource**: apps/v1/Deployment[api-server]

## ❌ Violations Found (3)

### Missing Resource Requests/Limits
**Severity**: HIGH
**Container**: api
**Current**: No resources defined
**Fix**: Add to container spec:
```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "1000m"
    memory: "512Mi"
```

### Missing Liveness Probe
**Severity**: HIGH
**Container**: api
**Current**: No livenessProbe defined
**Fix**: Add to container spec:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 15
  periodSeconds: 10
```

### Image Uses "latest" Tag
**Severity**: MEDIUM
**Container**: api
**Current**: image: api:latest
**Fix**: Use specific version: api:1.0.0

## Summary
- Total violations: 3
- Critical: 2 (resources, probes)
- Medium: 1 (image tag)
- Recommendation: Fix violations before deploying to production
```

**Example Output** (all pass):
```
# Kubernetes Manifest Validation Report

**Resource**: apps/v1/Deployment[api-server]

## ✅ All Checks Pass

This manifest follows CKA best practices and is recommended for production deployment.
```

---

## Success Criteria

**Agent Success**:
- ✅ Diagnoses 100% of major failure states (CrashLoopBackOff, Pending, OOMKilled, ImagePullBackOff)
- ✅ Suggests remediation steps for each diagnosis
- ✅ Handles truncated/incomplete kubectl output (provides best-guess analysis)
- ✅ Performance: <10 seconds to analyze typical pod output (SC-003)

**Skill Success**:
- ✅ Validates all required fields per CKA best practices
- ✅ Flags violations with clear remediation instructions
- ✅ Supports Deployment, StatefulSet, DaemonSet resources
- ✅ Reports no false positives on valid manifests

---

## Error Handling

| Error | Cause | User Action |
|-------|-------|-------------|
| "Invalid YAML/JSON" | Manifest syntax error | Fix YAML indentation/syntax |
| "No resources found" | Empty or unrecognized format | Provide valid Kubernetes manifest |
| "Truncated output" (Agent) | kubectl output cut off | Provide complete output if possible; agent will work with available data |
| "Unknown resource type" | CRD or uncommon resource | Focus on standard resources (Deployment, Pod, Service) |

---

## Assumptions

- Kubernetes 1.20+ (for modern probe fields)
- kubectl available for gathering diagnostic data
- User can provide representative subset of pod output (don't need entire cluster)
- Manifest validation assumes Deployment/StatefulSet/DaemonSet as primary resources
