# Agent: k8s-diagnosis

Interactive Kubernetes pod failure diagnosis agent that analyzes kubectl output to identify root causes and suggest remediation.

## Description

Analyzes Kubernetes pod states, logs, and events to rapidly diagnose failure conditions. Provides root cause analysis and actionable remediation steps for common failure states.

## Input

**Type**: kubectl output or Kubernetes events (text)

**Accepted Formats**:
- `kubectl describe pods --all-namespaces` (detailed pod info)
- `kubectl get events` (cluster events)
- `kubectl logs <pod-name>` (application logs)
- `kubectl get pods -o wide` (pod list with node info)
- Mixed output from multiple kubectl commands

**Validation**:
- Input must contain recognizable Kubernetes output
- May be truncated; agent provides best-guess diagnosis
- No live Kubernetes API calls (static analysis only)

## Processing Approach

### 1. Parse Input
Extract pod names, namespaces, and states from kubectl output

### 2. Identify Failure States
Classify each pod by state:
- **CrashLoopBackOff** - Application crashing
- **Pending** - Not scheduled
- **OOMKilled** - Out of memory
- **ImagePullBackOff** - Image pull failure
- **Running** (with high restart count)
- Other states

### 3. Diagnose Root Causes
For each failure state, analyze:

#### CrashLoopBackOff Diagnosis
- **Questions to answer**:
  - Are application startup logs showing errors?
  - Is the liveness probe timing too aggressive?
  - Are environment variables or configuration missing?
  - Is the app listening on the expected port?
  
- **Likely causes**:
  - Liveness probe with low `initialDelaySeconds` (too soon)
  - Missing environment variables for configuration
  - Application port mismatch
  - Startup checks failing
  
- **Remediation**:
  - Increase `initialDelaySeconds` (typically 10-30 seconds)
  - Verify all required environment variables are set
  - Check application logs for startup errors
  - Test application locally before deploying

#### Pending Diagnosis
- **Questions to answer**:
  - Are sufficient cluster resources available (CPU, memory)?
  - Do pod node selectors match available nodes?
  - Are required persistent volumes bound?
  - Are there image pull issues?
  
- **Likely causes**:
  - Insufficient memory or CPU in cluster
  - Node affinity constraints not matching any nodes
  - PersistentVolumeClaim not in Bound state
  - Image pull errors (registry auth, not found)
  
- **Remediation**:
  - Check cluster resources: `kubectl top nodes`
  - Scale cluster if needed
  - Adjust node selectors to match available nodes
  - Verify PVC is bound: `kubectl get pvc`
  - Check image pull events: `kubectl describe pod <name>`

#### OOMKilled Diagnosis
- **Questions to answer**:
  - Is memory usage approaching the limit?
  - Is memory usage growing over time?
  - Are there any obvious memory leaks?
  
- **Likely causes**:
  - Memory limit too low for application workload
  - Memory leak in application (steady growth)
  - Burst traffic causing temporary spike
  
- **Remediation**:
  - Increase memory limit (try 1.5x current)
  - Monitor memory usage: `kubectl top pod <name>`
  - Investigate memory leak if usage constantly grows
  - Consider using HPA for traffic-based scaling

#### ImagePullBackOff Diagnosis
- **Questions to answer**:
  - Does the image exist in the registry?
  - Is the image tag correct?
  - Are registry credentials available?
  - Is the node allowed to access the registry?
  
- **Likely causes**:
  - Image name typo or wrong registry
  - Tag doesn't exist (e.g., "latest" not available)
  - Missing ImagePullSecret
  - Registry authentication failed
  
- **Remediation**:
  - Verify image exists: `docker pull <image>`
  - Use specific version tags (not "latest")
  - Add ImagePullSecret if private registry
  - Test locally first

### 4. Generate Remediation Steps
For each diagnosed issue, provide:
1. **Specific action** (change in manifest or command)
2. **Reason** (why this fixes the issue)
3. **Verification step** (how to confirm fix)

## Output

**Format**: Markdown diagnostic report

**Structure**:
```markdown
## Pod Diagnosis Report

### Summary
[Number of pods analyzed, issues found, severity breakdown]

### Pod: [namespace/pod-name]
**State**: [CrashLoopBackOff | Pending | OOMKilled | etc.]
**Likely Cause**: [Root cause hypothesis]
**Evidence**: [Quotes from logs/events supporting diagnosis]
**Remediation Steps**:
1. [Action 1 with specific change]
2. [Action 2 with specific change]
3. [Verification step]

### Pod: [next-pod]
...

### General Recommendations
- [Cross-cutting fix if multiple pods have same issue]
- [Link to best practices or next steps]
```

### Example Output

```markdown
## Pod Diagnosis Report

### Summary
Analyzed 3 pods in production namespace:
- 2 pods in CrashLoopBackOff (high restart count)
- 1 pod in Pending (resource constraints)

### Pod: production/api-server-1
**State**: CrashLoopBackOff (8 restarts in 5 minutes)
**Likely Cause**: Liveness probe failing too quickly during startup
**Evidence**: 
- Logs show "Connection refused on port 8080"
- Probe checking at 5 seconds, but app needs 15+ seconds to start
- Probe period every 10 seconds

**Remediation Steps**:
1. Increase `initialDelaySeconds` from 5 to 15:
   ```yaml
   livenessProbe:
     httpGet:
       path: /health
       port: 8080
     initialDelaySeconds: 15  # Changed from 5
     periodSeconds: 10
   ```
2. Verify application startup time locally:
   ```bash
   docker run -p 8080:8080 api:1.0.0
   # Wait for "Server listening on 8080" message
   # Note the time required
   ```
3. Set `initialDelaySeconds` to slightly more than startup time
4. Redeploy: `kubectl apply -f deployment.yaml`
5. Check pod status: `kubectl describe pod api-server-1`

### Pod: production/worker-2
**State**: Pending (15+ minutes)
**Likely Cause**: Insufficient memory in cluster
**Evidence**: 
- Requests 2Gi memory but only 1Gi available on nodes
- Event: "Insufficient memory" across all nodes for 15 minutes

**Remediation Steps**:
1. Check current cluster memory:
   ```bash
   kubectl top nodes
   kubectl describe nodes
   ```
2. Option A (Recommended): Scale cluster to add memory
   ```bash
   # For EKS/GKE/AKS, scale your node group
   ```
3. Option B: Reduce memory request if safe
   ```yaml
   resources:
     requests:
       memory: "1Gi"  # Changed from 2Gi
   ```
4. Redeploy: `kubectl apply -f deployment.yaml`
5. Verify pod scheduling: `kubectl get pods`

### General Recommendations

- **CrashLoopBackOff Pattern**: Multiple pods failing suggests configuration issue
  - Verify environment variables are set correctly
  - Check ConfigMaps and Secrets are mounted properly
  - Test application locally with same config

- **Resource Shortage**: Cluster approaching capacity
  - Monitor with `kubectl top nodes` daily
  - Scale cluster proactively before hitting limits
  - Consider Horizontal Pod Autoscaler for traffic-based scaling

- **Next Steps**:
  - Apply fixes above and monitor pods for 5 minutes
  - Check pod logs: `kubectl logs <pod-name> --previous`
  - If issues persist, gather more data: `kubectl describe pod <name>`
```

## Error Handling

| Error | Cause | Recovery |
|-------|-------|----------|
| "No pods found in output" | Input doesn't contain Kubernetes format | Provide kubectl describe/logs output |
| "Incomplete output detected" | kubectl output truncated | Provide more complete output; agent will analyze partial data |
| "Unrecognized state" | Pod in unknown state | Agent provides general diagnostics; reference Kubernetes docs |
| "Insufficient context" | Output missing key details | Provide additional kubectl commands (logs, events, describe) |

## Assumptions

- Kubernetes 1.20+ (modern probe configuration)
- kubectl available on user's machine
- User can gather and provide representative pod output
- Input represents subset of cluster (not entire cluster needed)
- No live API access (static analysis of provided data)

## Performance Target

Diagnose typical 10-pod output in <10 seconds (SC-003)

## Related Documentation

- **Contract**: `specs/001-plugin-marketplace/contracts/k8s-troubleshooter-contract.md`
- **Examples**: `plugins/k8s-troubleshooter/examples/sample-outputs/`
- **Skill**: `manifest-validator.md` (for pre-deployment validation)
