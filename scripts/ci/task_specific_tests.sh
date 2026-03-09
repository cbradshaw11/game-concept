#!/usr/bin/env bash
set -euo pipefail

echo "[task-specific-tests] Starting"

# Default task-specific guard. Teams can extend this script per task type.
# For now, assert task templates and contributor workflow docs exist.
test -f .github/ISSUE_TEMPLATE/task.yml
test -f .github/PULL_REQUEST_TEMPLATE.md
test -f .github/CONTRIBUTING.md

echo "[task-specific-tests] Complete"
