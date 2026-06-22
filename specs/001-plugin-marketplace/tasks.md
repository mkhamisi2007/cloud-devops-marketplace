---
description: "Implementation tasks for Cloud DevOps Plugin Marketplace"
---

# Tasks: Cloud DevOps Plugin Marketplace

**Input**: Design documents from `specs/001-plugin-marketplace/`

**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Organization**: Tasks are grouped by user story and phase to enable independent implementation and testing of each story. All three plugins (terraform-standards, k8s-troubleshooter, aws-security-review) are P1 priority and can be developed in parallel after foundational setup.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no inter-task dependencies within same phase)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Marketplace structure per plan.md:
```
cloud-devops-marketplace/
├── .claude-plugin/
│   ├── marketplace.json
│   └── README.md
├── plugins/
│   ├── terraform-standards/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── commands/pre-apply-checklist.md
│   │   ├── hooks/hooks.json
│   │   └── README.md
│   ├── k8s-troubleshooter/
│   │   ├── .claude-plugin/plugin.json
│   │   ├── agents/k8s-diagnosis.md
│   │   ├── skills/manifest-validator.md
│   │   └── README.md
│   └── aws-security-review/
│       ├── .claude-plugin/plugin.json
│       ├── skills/iam-policy-reviewer.md
│       └── README.md
└── docs/
    └── ARCHITECTURE.md
```

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize marketplace project structure and create foundation for all plugins

- [x] T001 Create directory structure per plan.md: `plugins/terraform-standards/`, `plugins/k8s-troubleshooter/`, `plugins/aws-security-review/`, `docs/`
- [x] T002 [P] Initialize `.claude-plugin/` directory at repository root
- [x] T003 [P] Create `.gitignore` and `.gitattributes` for marketplace (exclude editor configs, build artifacts)
- [x] T004 [P] Initialize git repository (if not already initialized) with initial commit: "Initialize cloud-devops-marketplace repository"

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Create marketplace registry and plugin infrastructure that ALL plugins depend on

**⚠️ CRITICAL**: No plugin implementation can begin until this phase is complete

- [x] T005 Create marketplace registry file `.claude-plugin/marketplace.json` with plugin list structure from data-model.md (name, description, version, entrypoints, paths)
- [x] T006 [P] Create marketplace overview README at `.claude-plugin/README.md` covering: marketplace purpose, available plugins, installation instructions for each, troubleshooting
- [x] T007 [P] Create plugin template directory structure in each `plugins/<name>/` with .claude-plugin/, commands/, agents/, skills/, hooks/ subdirectories as needed
- [x] T008 [P] Create ARCHITECTURE.md at `docs/ARCHITECTURE.md` explaining: plugin independence principle, stateless design, contract-based communication, versioning strategy
- [x] T009 Create setup guide documentation at `.claude-plugin/SETUP.md` covering: prerequisites (Claude Code, git, kubectl), installation steps, verification checklist

**Checkpoint**: Foundational infrastructure complete. All plugins can now be implemented in parallel.

---

## Phase 3: User Story 1 - Terraform Standards Enforcement (Priority: P1) 🎯

**Goal**: Enable DevOps teams to enforce Terraform code standards via pre-apply checklist command and pre-commit credential-blocking hook

**Independent Test**: Developer commits Terraform files; hook blocks credentials; checklist identifies tagging/naming/encryption violations

### Implementation for terraform-standards Plugin

#### Plugin Infrastructure (T010-T012)

- [ ] T010 Create `.claude-plugin/plugin.json` for terraform-standards at `plugins/terraform-standards/.claude-plugin/plugin.json` with metadata: id, name, version, entrypoints (command: pre-apply-checklist, hook: commit-credential-blocker)
- [ ] T011 [P] Create terraform-standards README at `plugins/terraform-standards/README.md` covering: installation instructions, quick-start examples, configuration options, troubleshooting common issues
- [ ] T012 [P] Create example Terraform files at `plugins/terraform-standards/examples/` showing: compliant .tf files, examples of tag usage, naming conventions, encryption settings

#### Pre-Apply Checklist Command (T013-T016)

- [ ] T013 Create command definition file at `plugins/terraform-standards/commands/pre-apply-checklist.md` documenting: input format (file paths), processing rules from contract, output format (markdown report with violations)
- [ ] T014 [P] Implement tag validation logic (Environment and Owner tags mandatory) in command logic
- [ ] T015 [P] Implement naming convention validation (kebab-case enforcement) in command logic
- [ ] T016 [P] Implement encryption validation (S3 server_side_encryption_configuration and EBS encrypted=true) in command logic

#### Pre-Commit Hook (T017-T019)

- [ ] T017 Create hook configuration at `plugins/terraform-standards/hooks/hooks.json` defining: event (pre-commit), action (block), validation rules, error messages, recovery instructions per constitution Principle III
- [ ] T018 [P] Implement credential detection patterns (AWS keys, passwords, private keys) in hook logic with regex patterns from contract
- [ ] T019 Create hook script wrapper at `plugins/terraform-standards/hooks/install.sh` for user installation into .git/hooks/pre-commit

#### Testing & Validation (T020-T022)

- [ ] T020 [P] Create acceptance test for tag enforcement: Run checklist on file missing Environment/Owner tags; verify violation is flagged with remediation steps
- [ ] T021 [P] Create acceptance test for naming violations: Run checklist on resource with PascalCase name; verify kebab-case suggestion provided
- [ ] T022 [P] Create acceptance test for hook credential blocking: Attempt commit with hardcoded AWS key; verify hook blocks commit and logs recovery instructions

**Checkpoint**: User Story 1 (terraform-standards) is fully functional and independently testable. Command validates files; hook blocks unsafe commits.

---

## Phase 4: User Story 2 - Kubernetes Troubleshooting (Priority: P1)

**Goal**: Provide platform engineers rapid diagnosis of Kubernetes pod failures and manifest validation for CKA best practices

**Independent Test**: User provides kubectl output; agent diagnoses CrashLoopBackOff/Pending/OOMKilled; skill validates manifests for resource limits and probes

### Implementation for k8s-troubleshooter Plugin

#### Plugin Infrastructure (T023-T025)

- [ ] T023 Create `.claude-plugin/plugin.json` for k8s-troubleshooter at `plugins/k8s-troubleshooter/.claude-plugin/plugin.json` with metadata: id, name, version, entrypoints (agent: k8s-diagnosis, skill: manifest-validator)
- [ ] T024 [P] Create k8s-troubleshooter README at `plugins/k8s-troubleshooter/README.md` covering: installation, agent usage (diagnose pods), skill usage (validate manifests), examples, troubleshooting
- [ ] T025 [P] Create example manifests at `plugins/k8s-troubleshooter/examples/` showing: valid Deployment with resource limits and probes, invalid manifest with violations, sample kubectl outputs for various failure states

#### Pod Diagnosis Agent (T026-T029)

- [ ] T026 Create agent definition at `plugins/k8s-troubleshooter/agents/k8s-diagnosis.md` documenting: input (kubectl output), reasoning approach (parse states → hypothesize causes → suggest remediation), output format (markdown diagnostic report)
- [ ] T027 [P] Implement CrashLoopBackOff diagnosis logic: analyze logs and events; suggest health probe, environment, or config issues
- [ ] T028 [P] Implement Pending diagnosis logic: check resource availability, node affinity, PVC status
- [ ] T029 [P] Implement OOMKilled diagnosis logic: identify memory limit issues and suggest increases

#### Manifest Validation Skill (T030-T033)

- [ ] T030 Create skill definition at `plugins/k8s-troubleshooter/skills/manifest-validator.md` documenting: input (Kubernetes manifest), validation rules (resource requests/limits, health probes, image versioning), output format (markdown report with violations or pass)
- [ ] T031 [P] Implement resource request/limit validation: check every container has cpu/memory requests and limits
- [ ] T032 [P] Implement health probe validation: check Deployments have liveness and readiness probes with appropriate timeouts
- [ ] T033 [P] Implement image version validation: check images use specific tags (no "latest"), flagging if versions are missing

#### Testing & Validation (T034-T037)

- [ ] T034 [P] Create acceptance test for CrashLoopBackOff diagnosis: Provide kubectl output with CrashLoopBackOff; verify agent suggests health probe or startup issues
- [ ] T035 [P] Create acceptance test for Pending diagnosis: Provide kubectl output with Pending status; verify agent explains resource shortage or node affinity issues
- [ ] T036 [P] Create acceptance test for manifest validation: Provide Deployment missing resource limits and health probes; verify skill flags both violations
- [ ] T037 Create performance test for agent response time: Measure time to diagnose typical 10+ pod output; verify <10 second target (SC-003)

**Checkpoint**: User Story 2 (k8s-troubleshooter) is fully functional and independently testable. Agent diagnoses pod failures; skill validates manifest best practices.

---

## Phase 5: User Story 3 - AWS Security Review (Priority: P1)

**Goal**: Flag overly permissive IAM policies, public S3 buckets, and unrestricted security groups to enable security officers to audit configurations

**Independent Test**: User provides AWS configuration; skill flags overly permissive IAM, public S3, unrestricted security groups; suggests remediation

### Implementation for aws-security-review Plugin

#### Plugin Infrastructure (T038-T040)

- [ ] T038 Create `.claude-plugin/plugin.json` for aws-security-review at `plugins/aws-security-review/.claude-plugin/plugin.json` with metadata: id, name, version, entrypoints (skill: iam-policy-reviewer)
- [ ] T039 [P] Create aws-security-review README at `plugins/aws-security-review/README.md` covering: installation, skill usage examples, configuration analysis format, troubleshooting
- [ ] T040 [P] Create example AWS configurations at `plugins/aws-security-review/examples/` showing: overly permissive IAM policy, public S3 bucket, unrestricted security group, remediated versions of each

#### IAM Policy Reviewer Skill (T041-T045)

- [ ] T041 Create skill definition at `plugins/aws-security-review/skills/iam-policy-reviewer.md` documenting: input (IAM policy JSON/YAML), validation rules from contract, output format (markdown report with violations and remediation)
- [ ] T042 [P] Implement overly permissive IAM policy detection: flag Action="*" and Resource="*" patterns; suggest narrowing to specific actions and resources
- [ ] T043 [P] Implement public S3 bucket detection: flag Principal="*" in bucket policies and public ACLs; suggest restricting to specific principals
- [ ] T044 [P] Implement security group unrestricted access detection: flag 0.0.0.0/0 on sensitive ports (22, 3306, 5432, 3389); allow for ports 80/443
- [ ] T045 Create validation for cloudformation templates: extend skill to parse CloudFormation YAML/JSON and apply same security rules

#### Testing & Validation (T046-T049)

- [ ] T046 [P] Create acceptance test for overly permissive IAM: Provide policy with Action="*"; verify skill flags and suggests narrowing
- [ ] T047 [P] Create acceptance test for public S3 bucket: Provide S3 bucket policy with Principal="*"; verify skill flags public access risk and suggests remediation
- [ ] T048 [P] Create acceptance test for unrestricted security group: Provide security group allowing 0.0.0.0/0 on port 22; verify skill flags and suggests IP restriction
- [ ] T049 Create performance test for policy review: Analyze complex multi-statement policy; verify <10 second analysis time per SC-004

**Checkpoint**: User Story 3 (aws-security-review) is fully functional and independently testable. Skill identifies security gaps in IAM, S3, and security groups.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Finalize marketplace documentation, examples, and end-to-end validation

- [ ] T050 [P] Create MARKETPLACE_REGISTRY.md at marketplace root documenting: how to discover plugins, version checking, updating plugins, reporting issues
- [ ] T051 [P] Create QUICKSTART.md at marketplace root with step-by-step installation and validation of all three plugins independently
- [ ] T052 [P] Create TROUBLESHOOTING.md covering: common installation issues, plugin not found, command not recognized, performance problems
- [ ] T053 Update .claude-plugin/marketplace.json with all three plugins (terraform-standards, k8s-troubleshooter, aws-security-review) and latest versions
- [ ] T054 [P] Create CONTRIBUTING.md documenting: plugin development guidelines, testing requirements, code style, submission process
- [ ] T055 [P] Create VERSIONING.md explaining: semantic versioning strategy, how to bump plugin versions, marketplace version changes
- [ ] T056 Create LICENSE file for marketplace and plugins (recommend MIT or Apache 2.0 for DevOps tools)
- [ ] T057 [P] Run end-to-end quickstart validation: Install each plugin; run all three plugins; verify independent functionality; verify outputs match contracts
- [ ] T058 [P] Create examples directory at `examples/` with complete terraform, kubernetes, AWS configuration samples showing: compliant code, violations, remediation
- [ ] T059 Run acceptance test suite against all plugins: Execute all test scenarios from Phases 3-5; verify all pass with <10 second response times

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all plugin development
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - Plugins CAN develop in parallel once Foundational is done
  - Each plugin is independently testable
  - No inter-plugin dependencies
- **Polish (Phase 6)**: Depends on all plugins being functional

### Plugin Parallelization

Once Foundational (Phase 2) completes, all three plugins can be developed simultaneously:

```
Developer A: Phase 3 (terraform-standards)
Developer B: Phase 4 (k8s-troubleshooter)
Developer C: Phase 5 (aws-security-review)
All: Phase 6 (Polish & validation)
```

### Within Each Plugin Phase

**Recommended order** (but marked [P] tasks can run in parallel):

1. Plugin infrastructure (manifest, README, examples)
2. Core feature implementation (command/agent/skill logic)
3. Hook/integration setup
4. Test implementation
5. Documentation finalization

---

## Parallel Opportunities

### Phase 1 (Setup)
- T002 (initialize .claude-plugin/) and T003 (gitignore) can run in parallel
- T002, T003, T004 all parallelizable (different files)

### Phase 2 (Foundational)
- T006 (marketplace README), T007 (plugin templates), T008 (ARCHITECTURE.md) all parallelizable
- T009 depends on directory structure from T005

### Phase 3 (terraform-standards)
- Plugin infrastructure tasks T010-T012 parallelizable
- Command validation tasks T014-T016 parallelizable (different validation modules)
- Hook implementation tasks T017-T019 parallelizable
- Test tasks T020-T022 parallelizable

### Phase 4 (k8s-troubleshooter)
- Plugin infrastructure tasks T023-T025 parallelizable
- Diagnosis logic tasks T027-T029 parallelizable (different failure states)
- Validation logic tasks T031-T033 parallelizable (different validation types)
- Test tasks T034-T037 parallelizable

### Phase 5 (aws-security-review)
- Plugin infrastructure tasks T038-T040 parallelizable
- IAM detection logic T042-T044 parallelizable (different policy types)
- Test tasks T046-T049 parallelizable

### Phase 6 (Polish)
- Documentation tasks T050-T052, T054-T056 parallelizable (different docs)
- Examples and validation T057-T059 can start once plugins functional

---

## Implementation Strategy

### MVP First (Recommended)

**Minimal Viable Product scope**: Just User Story 1 (terraform-standards)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks stories)
3. Complete Phase 3: terraform-standards only
4. **STOP and VALIDATE**: Test terraform-standards independently
5. Deploy/demo User Story 1
6. Proceed to User Story 2 if time/resources permit

**Time estimate**: ~2 weeks for MVP (one developer)

### Incremental Delivery (Recommended for Full Feature)

1. Phases 1-2: Setup + Foundational (~3 days)
2. Phase 3: terraform-standards (~1 week)
3. Phase 4: k8s-troubleshooter (~1 week) - parallel with Phase 3 if 2+ developers
4. Phase 5: aws-security-review (~1 week) - parallel with Phases 3-4 if 3+ developers
5. Phase 6: Polish + validation (~1 week)

**Total time estimate**: ~4 weeks with sequential delivery; 2 weeks with 3-person parallel team

### Parallel Team Strategy (Full Feature, 3+ Developers)

With three developers:

1. **Week 1** (all together):
   - Developer A+B+C: Complete Phase 1 (Setup)
   - Developer A+B+C: Complete Phase 2 (Foundational)

2. **Week 2** (parallel):
   - Developer A: Phase 3 (terraform-standards)
   - Developer B: Phase 4 (k8s-troubleshooter)
   - Developer C: Phase 5 (aws-security-review)

3. **Week 3** (parallel):
   - All developers: Continue assigned plugins (T020+, T034+, T046+)
   - Each plugin reaches independent functionality

4. **Week 4** (integration):
   - Developer A+B+C: Phase 6 (Polish, integration tests, documentation)
   - Deploy full marketplace

---

## Notes

- [P] tasks = parallelizable (different files, independent logic, no cross-task dependencies)
- [Story] label maps task to specific user story for traceability
- Each plugin should be independently completable and testable
- Plugins follow constitution principles: independent installation, English documentation, clear error logging
- Contract validation: each plugin's output must match its contract definition
- Performance targets: all analysis tools must respond in <10 seconds (SC-003, SC-004)
- Commit after each task or logical group (recommend: after each [Story] phase completes)
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-plugin dependencies
