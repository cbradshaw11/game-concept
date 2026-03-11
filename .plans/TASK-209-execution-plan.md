# TASK-209 Execution Plan: Enable Godot runtime execution in CI headless tests

## Status
in_progress

## Scope

### In scope
- Verify `.github/workflows/headless-tests.yml` installs godot4 on the CI runner
- Verify `scripts/ci/headless_tests.sh` executes real Godot tests when runtime is available
- Confirm local lint checks still pass

### Out of scope
- Changing test script logic or assertions
- Adding new test coverage
- Modifying lint, smoke-scene, or task-specific-tests workflows

## Context

> NOTE: As of the migration audit, the implementation appears complete.
> `headless-tests.yml` already contains an "Install Godot runtime" step that
> downloads, unzips, and installs `godot4` to `/usr/local/bin/godot4`.
> `headless_tests.sh` already branches on `command -v godot4` to run real tests
> vs structural fallback.
>
> Delivery work may be limited to running AC verification and closing the ticket.

## AC to Verification Mapping

| AC | Description | Verification Command |
|----|-------------|----------------------|
| ac1 | headless-tests workflow installs godot4 | `grep -i 'install godot' .github/workflows/headless-tests.yml` |
| ac2 | CI executes test scripts with runtime | `grep 'godot4' .github/workflows/headless-tests.yml` |
| ac3 | Local lint checks still pass | `bash scripts/ci/lint.sh` |

## Slices

### Slice 1: Verify and close (likely path)

**Files to modify:** `.github/workflows/headless-tests.yml` (if any gap found)
**Files read-only:** `scripts/ci/headless_tests.sh`
**Prohibited changes:** test script logic, other workflow files

**Steps:**
1. Run all three AC verification commands
2. If all pass, transition ticket to `verifying`, then `done`
3. If a gap is found (e.g. godot4 binary not properly invoked), make minimal targeted fix

## Verification Commands (authoritative gate)

```bash
# AC1: workflow installs godot
grep -i 'install godot' .github/workflows/headless-tests.yml

# AC2: workflow uses godot4
grep 'godot4' .github/workflows/headless-tests.yml

# AC3: local lint passes
bash scripts/ci/lint.sh
```

## Dependency Impact

Closing this ticket unblocks M2 milestone verifier sign-off. All other M2 tasks
(TASK-201 through TASK-208) are already done.
