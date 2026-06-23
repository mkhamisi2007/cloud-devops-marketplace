# k8s-troubleshooter Plugin

Diagnose Kubernetes pod failures and validate manifest best practices in seconds.

## Overview

The k8s-troubleshooter plugin helps platform engineers rapidly resolve Kubernetes issues through:

- 🔍 **Interactive diagnosis agent**: Analyze kubectl output to identify pod failure root causes
- ✅ **Manifest validator skill**: Validate Kubernetes Deployments against CKA best practices
- 💡 **Actionable remediation**: Every issue includes specific fix instructions

## Installation

This plugin is part of the Cloud DevOps Marketplace. To install:

```bash
/plugin install k8s-troubleshooter@cloud-devops-marketplace
```

## Quick Start

### 1. Diagnose Pod Failures (Interactive Agent)

Quickly identify why pods are failing and get remediation steps:

```bash
/plugin run k8s-troubleshooter k8s-diagnosis
```

Provide kubectl output when prompted (paste output from kubectl describe, logs, or events).

**Example**:
```
Kubernetes output: 
[Paste output from: kubectl describe pods --all-namespaces]
```

**Output**: Markdown report with root cause analysis and remediation steps.

### 2. Validate Deployment Manifest (Skill)

Ensure your manifests follow CKA best practices before deployment:

```bash
/plugin run k8s-troubleshooter manifest-validator
```

Provide your Kubernetes manifest (YAML or JSON) when prompted.

**Example**:
```
Kubernetes manifest:
[Paste your deployment.yaml here]
```

**Output**: Report showing violations or pass confirmation.

## Features

### Pod Diagnosis Agent

Analyzes kubectl output to diagnose common Kubernetes failure states:

#### 1. CrashLoopBackOff
- **Cause**: Application crashes on startup or fails health checks
- **Diagnosis**: Checks startup logs, health probe timing, environment variables
- **Remediation**: Adjust probe timing, fix configuration, review startup process

#### 2. Pending
- **Cause**: Pod cannot be scheduled on any node
- **Diagnosis**: Checks resource availability, node affinity, storage binding
- **Remediation**: Scale cluster, adjust selectors, provision storage

#### 3. OOMKilled
- **Cause**: Container exceeds memory limit
- **Diagnosis**: Checks memory usage vs. limits, identifies leaks
- **Remediation**: Increase memory limit, investigate memory leak

#### 4. ImagePullBackOff
- **Cause**: Container image cannot be pulled from registry
- **Diagnosis**: Checks image name, tag, registry credentials
- **Remediation**: Fix image reference, add pull secrets, check registry access

**Performance**: Diagnoses typical 10+ pod output in <10 seconds

### Manifest Validator Skill

Validates Kubernetes manifests against CKA best practices:

#### 1. Resource Requests & Limits
- Every container must specify CPU and memory requests and limits
- Enables proper scheduling and pod eviction policies
- **Violations show**: Missing resource blocks with fix examples

#### 2. Health Probes
- Every Deployment must have liveness AND readiness probes
- Enables Kubernetes to restart failed pods and route traffic properly
- **Violations show**: Missing probe configuration with recommended settings

#### 3. Image Versioning
- Images must use specific version tags (never "latest")
- Ensures deterministic deployments; prevents breaking changes
- **Violations show**: Images using "latest" with fix examples

#### 4. RBAC (Role-Based Access Control)
- Service accounts must follow principle of least privilege
- No deployment should use cluster-admin role
- **Violations show**: Over-privileged service accounts with reduced permissions

**Exit Codes**:
- `0` = All checks pass
- `1` = Violations found (not production-ready)

## Usage Examples

### Example 1: Diagnose Pod Failures

```bash
/plugin run k8s-troubleshooter k8s-diagnosis

# When prompted, paste kubectl output:
kubectl describe pods --all-namespaces
```

Output:
```
## Pod Diagnosis Report

### Summary
Analyzed 3 pods in production namespace:
- 2 pods in CrashLoopBackOff
- 1 pod in Pending

### Pod: production/api-server-1
**State**: CrashLoopBackOff
**Likely Cause**: Liveness probe failing too quickly
**Evidence**: Logs show connection refused on port 8080
**Remediation Steps**:
1. Increase initialDelaySeconds from 5 to 15
2. Test app startup locally: docker run -p 8080:8080 api:1.0.0
3. Verify port 8080 is listening before probe starts
```

### Example 2: Validate Deployment Manifest

```bash
/plugin run k8s-troubleshooter manifest-validator

# When prompted, paste your manifest:
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-server
spec:
  template:
    spec:
      containers:
      - name: api
        image: api:latest
        # Missing: resources, livenessProbe, readinessProbe
```

Output:
```
# Kubernetes Manifest Validation Report

**Resource**: apps/v1/Deployment[api-server]

## ❌ Violations Found (3)

### Missing Resource Requests/Limits
**Severity**: HIGH
**Container**: api
**Fix**: Add to container spec:
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "1000m"
    memory: "512Mi"

### Missing Liveness Probe
**Severity**: HIGH

### Image Uses "latest" Tag
**Severity**: MEDIUM
**Current**: api:latest
**Fix**: Use specific version: api:1.0.0
```

### Example 3: Multiple Pods with Same Issue

```bash
/plugin run k8s-troubleshooter k8s-diagnosis

# Output includes:
### General Recommendations
- Multiple pods failing with insufficient memory
- Action: Scale up cluster resources or reduce memory requests
```

## Configuration

The plugin validates against these standards:

| Standard | Requirement | Scope |
|----------|------------|-------|
| **Resource Limits** | CPU and memory requests/limits on all containers | All Deployments |
| **Health Probes** | Liveness and readiness probes | All Deployments |
| **Image Tags** | Specific version tags (no "latest") | All container images |
| **RBAC** | Service account without cluster-admin binding | All Deployments |

## Examples

See `examples/` directory for:
- ✅ `valid-deployment.yaml` - Properly configured Deployment
- ❌ `invalid-deployment.yaml` - Missing probes, limits, versioning
- 📋 `sample-outputs/` - Typical kubectl outputs for various failure states

## Troubleshooting

### Agent: "No pods found in output"

**Cause**: Input doesn't contain recognizable Kubernetes output  
**Fix**: Provide output from kubectl commands:

```bash
kubectl describe pods --all-namespaces
kubectl get events
kubectl logs <pod-name>
```

### Agent: "Incomplete output"

**Cause**: kubectl output was truncated  
**Fix**: Provide complete output if possible; agent will diagnose with available data

### Skill: "Invalid YAML/JSON"

**Cause**: Manifest has syntax errors  
**Fix**: Validate locally first:

```bash
kubectl apply -f deployment.yaml --dry-run=client
```

### Skill: "Unsupported resource type"

**Cause**: Using non-standard Kubernetes resource  
**Fix**: Focus on Deployment, StatefulSet, DaemonSet; extract to separate file if needed

## Standards Reference

This plugin enforces standards aligned with:

- **Certified Kubernetes Administrator (CKA)** exam objectives
  - Pod resource management and scheduling
  - Health probes for reliability
  - RBAC and security best practices
  
- **Kubernetes Best Practices**
  - Resource requests enable fair scheduling
  - Health probes enable self-healing
  - Image versioning prevents breaking changes

## Performance

- **Agent**: Diagnoses typical 10+ pod output in <10 seconds
- **Skill**: Validates manifest in <5 seconds

## Support

For issues or questions:
1. Check the Troubleshooting section above
2. Review examples in `examples/` directory
3. See main marketplace README for general plugin help

---

**Version**: 1.0.0  
**Author**: DevOps Team  
**License**: MIT
