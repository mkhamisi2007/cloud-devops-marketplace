# Feature Specification: Cloud DevOps Plugin Marketplace

**Feature Branch**: `001-plugin-marketplace`

**Created**: 2026-06-22

**Status**: Draft

**Input**: Build a private Claude Code plugin marketplace containing three plugins: terraform-standards (tagging/encryption enforcement), k8s-troubleshooter (pod diagnosis), and aws-security-review (security flagging).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Terraform Standards Enforcement (Priority: P1)

A DevOps team wants to prevent Terraform code from being deployed without proper tagging, naming conventions, and encryption settings. The terraform-standards plugin helps teams maintain infrastructure standards through automated checks and commit-blocking enforcement.

**Why this priority**: Terraform infrastructure standardization is foundational—preventing misconfigured resources at commit time reduces security incidents and operational debt.

**Independent Test**: A developer attempts to commit Terraform files with hardcoded credentials or missing mandatory tags. The plugin should block the commit and suggest how to fix it independently, without needing the other plugins.

**Acceptance Scenarios**:

1. **Given** a developer commits Terraform files with hardcoded AWS credentials, **When** the commit hook runs, **Then** the commit is blocked with a clear message explaining the issue and remediation steps

2. **Given** a storage resource in Terraform lacks encryption configuration, **When** the pre-apply checklist command runs, **Then** the tool flags the resource and explains what encryption settings must be added

3. **Given** a resource uses PascalCase naming instead of kebab-case, **When** the pre-apply checklist runs, **Then** the tool flags the naming violation with examples of correct naming

4. **Given** a resource lacks mandatory Environment and Owner tags, **When** the pre-apply checklist runs, **Then** the tool lists which resources are missing tags and suggests valid tag values

---

### User Story 2 - Kubernetes Troubleshooting (Priority: P1)

A platform engineer faces a production issue: several pods are in CrashLoopBackOff, some are pending, and others have been OOMKilled. The k8s-troubleshooter agent consumes kubectl output and quickly suggests root causes and remediation steps without requiring manual inspection of logs.

**Why this priority**: Rapid diagnosis of Kubernetes failures is critical for platform reliability. Being able to paste kubectl output and get actionable insights reduces mean-time-to-recovery.

**Independent Test**: A user provides kubectl output showing multiple pod failure states. The tool independently analyzes the output, diagnoses the issues, and suggests fixes without needing the terraform or AWS plugins.

**Acceptance Scenarios**:

1. **Given** kubectl output showing a pod in CrashLoopBackOff state, **When** the k8s-troubleshooter analyzes it, **Then** it suggests that the pod is either missing health probes, has insufficient resources, or is failing startup checks

2. **Given** kubectl output showing pending pods, **When** the tool analyzes it, **Then** it explains whether the issue is resource shortage, node affinity constraints, or persistent volume unavailability

3. **Given** kubectl output showing OOMKilled containers, **When** the tool analyzes it, **Then** it recommends increasing resource limits and explains how to set proper requests/limits

4. **Given** a deployment manifest provided for review, **When** the skill checks best practices, **Then** it flags missing health probes (liveness/readiness) and missing resource requests/limits

---

### User Story 3 - AWS Security Review (Priority: P1)

A security officer wants continuous assurance that AWS resources follow the principle of least privilege. The aws-security-review skill automatically flags overly permissive configurations without requiring manual policy reviews.

**Why this priority**: Preventing overly permissive IAM policies and public bucket exposure reduces the blast radius of compromised credentials and unauthorized access incidents.

**Independent Test**: A user provides AWS resource configurations or IAM policies. The tool independently identifies security gaps (overly permissive IAM, public S3 buckets, unrestricted security groups) without needing the Terraform or Kubernetes plugins.

**Acceptance Scenarios**:

1. **Given** an IAM policy that grants `Action: "*"` on all resources, **When** the tool reviews it, **Then** it flags this as overly permissive and suggests narrowing the scope to specific actions and resources

2. **Given** an S3 bucket configured with public read access, **When** the tool analyzes the configuration, **Then** it flags the bucket as publicly accessible and recommends restricting access to authenticated principals

3. **Given** a security group allowing inbound traffic from 0.0.0.0/0 on port 22, **When** the tool reviews it, **Then** it flags unrestricted SSH access and explains the security risk

4. **Given** a security group allowing 0.0.0.0/0 on port 80 (HTTP), **When** the tool reviews it, **Then** it acknowledges this is typically acceptable for web traffic but recommends HTTPS (port 443) instead

---

### Edge Cases

- What happens when a Terraform file has both compliant and non-compliant resources? (Hook should list all violations, not just fail on first one)
- How does the k8s-troubleshooter handle truncated or incomplete kubectl output? (Should provide best-guess diagnosis based on available data)
- How does aws-security-review handle resources from multiple AWS accounts? (Should analyze each account independently)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: terraform-standards MUST enforce that all resources have mandatory Environment and Owner tags
- **FR-002**: terraform-standards MUST enforce kebab-case naming convention on resource names
- **FR-003**: terraform-standards MUST enforce encryption on storage resources (S3, EBS)
- **FR-004**: terraform-standards MUST provide a command that runs a pre-apply checklist against Terraform files
- **FR-005**: terraform-standards MUST block commits (via hook) if they contain hardcoded credentials (AWS keys, passwords, tokens)
- **FR-006**: k8s-troubleshooter MUST analyze kubectl output and suggest root causes for CrashLoopBackOff, Pending, and OOMKilled states
- **FR-007**: k8s-troubleshooter MUST validate Kubernetes Deployment manifests for resource requests/limits and health probes
- **FR-008**: k8s-troubleshooter MUST provide a skill that enforces manifest best practices
- **FR-009**: aws-security-review MUST identify IAM policies with overly permissive actions (wildcards without scope)
- **FR-010**: aws-security-review MUST flag S3 buckets with public read/write access
- **FR-011**: aws-security-review MUST flag security groups allowing unrestricted access (0.0.0.0/0) on ports other than 80/443
- **FR-012**: Each plugin MUST be independently installable without dependencies on other marketplace plugins
- **FR-013**: Each plugin MUST include documentation in English covering installation, usage, configuration, and troubleshooting
- **FR-014**: Hooks (terraform-standards credential blocking) MUST log clear, actionable messages when blocking an action

### Key Entities

- **Plugin**: A standalone, independently installable Claude Code extension (Command, Skill, Agent, or Hook)
- **Terraform Resource**: Infrastructure configuration object being validated
- **Kubernetes Pod**: Container workload being diagnosed
- **AWS Resource Configuration**: IAM policy, S3 bucket, or security group being reviewed

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can install any single plugin independently without needing others
- **SC-002**: A DevOps team using terraform-standards can block all commits with hardcoded credentials within their project
- **SC-003**: A platform engineer can paste kubectl output and receive diagnostic suggestions in under 10 seconds
- **SC-004**: A security officer can review AWS configurations and identify overly permissive policies within minutes instead of hours
- **SC-005**: Each plugin has complete English documentation covering installation, quick-start, configuration, and troubleshooting
- **SC-006**: When a hook blocks a commit, the log message clearly explains what was wrong and how to fix it

## Assumptions

- Developers have access to kubectl with proper credentials for Kubernetes diagnostics
- Terraform files are plain-text and can be analyzed without execution
- AWS configurations are provided as JSON or YAML exports
- Each plugin will be installed separately into individual Claude Code projects
- The marketplace does not require a centralized registry—plugins are installed directly from documentation
- English is the primary language for all documentation and user-facing messaging
- Kubernetes best practices refer to CKA exam standards
- AWS security practices align with AWS Well-Architected Framework Security Pillar
- Terraform standards should align with AWS Well-Architected security principles
