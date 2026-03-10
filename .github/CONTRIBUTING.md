# Multi-Agent Delivery Workflow

## Core Rules
1. One issue per branch and one branch per PR.
2. Branch naming: `codex/<task-id>-<short-slug>`.
3. PR title: `[TASK-<id>] <title>`.
4. Draft PR required until verifier sign-off is complete.
5. Maximum 3 concurrent `state:in-progress` tasks.
6. Merge strategy is squash only. Manual merge only.

## Task Lifecycle
1. `state:backlog`
2. `state:ready`
3. `state:in-progress`
4. `state:in-review`
5. `state:verified`
6. `state:done`

## Label Policy
Each issue must have exactly one label from each set:
1. `type:*`
2. `area:*`
3. `priority:*`
4. `state:*`
5. `risk:*`

Optional labels:
- `blocked`

## Agent Pickup Protocol
1. Pick only issues in `state:ready` with no unresolved dependencies.
2. Claim issue and move to `state:in-progress`.
3. Work only within allowed files unless issue is re-scoped.
4. Open Draft PR with linked issue and completed PR template fields.

## Verification Protocol
1. Required checks must pass:
- `headless-tests`
- `lint`
- `smoke-scene`
- `task-specific-tests`
2. Request verifier review explicitly in PR.
3. Address verifier findings before status can move to `state:verified`.

## Completion Protocol
1. Verifier approves.
2. Maintainer performs manual squash merge to `main`.
3. Close issue and set `state:done`.
4. Update milestone checkpoint issue with evidence links.

## Project Mapping Automation
1. The `project-policy-sync` workflow maps label state to Project fields.
2. PRs must include closing keywords in body, for example `Closes #12`, so linked issue state can be advanced.
3. The workflow uses repository secret `PROJECT_TOKEN` with `project` scope to update GitHub Projects v2 fields.

## Milestone Gate
A milestone is complete only when:
1. All child tasks are `state:done`.
2. All milestone demo scenarios pass on `main`.
3. No open `priority:p0` issues remain in milestone scope.
4. Verifier sign-off is captured in the milestone checkpoint issue.
