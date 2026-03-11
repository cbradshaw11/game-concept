# M1 Foundation — Sprint Closeout

## Status
done

## Summary
M1 Foundation milestone delivered all 8 infra tasks establishing the multi-agent
delivery workflow: label normalization, issue and PR templates, CI workflows,
branch protection, squash-only merge policy, GitHub Projects v2 board, and M2
backlog seeding.

## Delivered Tickets

| ID | Title | Area |
|----|-------|------|
| TASK-101 | Add queue labels and normalize default label set | infra |
| TASK-102 | Add issue templates for task and milestone intake | infra |
| TASK-103 | Add PR template with verifier section | infra |
| TASK-104 | Add CI workflows for required status checks | infra |
| TASK-105 | Configure squash-only merge policy | infra |
| TASK-106 | Apply branch protection for main required checks | infra |
| TASK-107 | Create Projects v2 board and status automations | infra |
| TASK-108 | Seed M2 Ring1 slice backlog with atomic tasks | infra |

## Exit Criteria
- [x] All M1 tasks done
- [x] Required checks green on main
- [x] Verifier sign-off linked

## Artifacts
- `.github/ISSUE_TEMPLATE/task.yml`
- `.github/ISSUE_TEMPLATE/milestone-checkpoint.yml`
- `.github/PULL_REQUEST_TEMPLATE.md`
- `.github/workflows/lint.yml`
- `.github/workflows/smoke-scene.yml`
- `.github/workflows/task-specific-tests.yml`
- `.github/workflows/headless-tests.yml`
- `tasks/QUEUE.md`

## Notes
History reconstructed from `tasks/milestones/M1-foundation.md` and `tasks/QUEUE.md`
during migration to local ticket system. Individual branch/PR/commit metadata was
not captured in the original markdown system.
