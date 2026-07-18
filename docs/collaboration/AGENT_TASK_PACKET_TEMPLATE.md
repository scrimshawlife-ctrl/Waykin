# Agent Task Packet Template

Copy this template into the coding-agent session. Complete every required field before implementation.

```yaml
task_id: WAYKIN-<issue>
issue_url:
branch:
implementation_owner:
agent:

objective:

user_visible_outcome:

acceptance_criteria:
  -

authority:
  binding:
    - WAYKIN_SPEC.md
    - ARCHITECTURE.md
    - AGENTS.md
    - CONTRIBUTING.md
  issue_specific:
    -
  reference_only:
    -

allowed_paths:
  -

frozen_paths:
  - Sources/WaykinCore/** # remove only when issue explicitly authorizes core work
  - App/Persistence/**
  - App/Audio/**

explicit_non_goals:
  - no incidental scope expansion
  - no parallel subsystem creation
  - no unapproved persistence or Bond changes
  - no device-validation claims without direct evidence

required_commands:
  - make build
  - make test
  - make validate
  - git diff --check

additional_validation:
  -

device_evidence:
  required: false
  protocol:

completion_report:
  changed_files:
  intentionally_unchanged:
  commands_run:
  results:
  assumptions:
  unresolved:
  recommended_next_action:
```

## Agent Directive

Implement only the issue acceptance criteria inside the allowed paths. Treat frozen paths as read-only. Follow the binding documents in the listed order. Prefer the smallest coherent patch and existing repository owners. Do not introduce a new runtime truth source or promote reference material into product scope.

When evidence is incomplete, report `NOT_COMPUTABLE`; do not guess. If requirements conflict, stop and report the conflict instead of choosing a broader interpretation.

## Human Review Checklist

Before accepting the agent output, the implementation owner must confirm:

- [ ] The diff is limited to the issue.
- [ ] No frozen path changed.
- [ ] No duplicate subsystem was introduced.
- [ ] Tests cover the changed behavior.
- [ ] Documentation reflects only observed or explicitly inferred behavior.
- [ ] Required commands were run and copied accurately.
- [ ] Device-dependent claims have direct evidence or remain `NOT_COMPUTABLE`.
- [ ] The PR is opened as draft with a complete handoff.
