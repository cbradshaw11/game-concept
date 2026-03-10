---
id: TASK-209
title: Enable Godot runtime execution in CI headless tests
type: chore
priority: p1
area: infra
risk: medium
milestone: M2 Ring1 Slice
depends-on: none
status: in-progress
---

## Objective
Ensure CI runs real Godot headless tests instead of the structural fallback.

## Allowed Files
- `.github/workflows/headless-tests.yml`

## Acceptance Criteria
- [ ] `headless-tests` workflow installs `godot4` on runner
- [ ] CI executes test scripts with runtime available
- [ ] Local workflow/lint checks still pass
