#!/usr/bin/env bash
set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is required" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required" >&2
  exit 1
fi

ISSUE_NUMBER=""
WORKFLOW_STATE=""
SET_STATE_LABEL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue)
      ISSUE_NUMBER="$2"
      shift 2
      ;;
    --workflow)
      WORKFLOW_STATE="$2"
      shift 2
      ;;
    --set-state-label)
      SET_STATE_LABEL="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$ISSUE_NUMBER" ]]; then
  echo "--issue is required" >&2
  exit 1
fi

PROJECT_OWNER="${PROJECT_OWNER:-cbradshaw11}"
PROJECT_NUMBER="${PROJECT_NUMBER:-1}"
REPO_OWNER="${REPO_OWNER:-cbradshaw11}"
REPO_NAME="${REPO_NAME:-game-concept}"

issue_json="$(gh issue view "$ISSUE_NUMBER" --repo "$REPO_OWNER/$REPO_NAME" --json number,state,labels,title,milestone)"
issue_state="$(echo "$issue_json" | jq -r '.state')"

# Normalize state label category when directed.
if [[ -n "$SET_STATE_LABEL" ]]; then
  for lbl in state:backlog state:ready state:in-progress state:in-review state:verified state:done; do
    gh issue edit "$ISSUE_NUMBER" --repo "$REPO_OWNER/$REPO_NAME" --remove-label "$lbl" >/dev/null 2>&1 || true
  done
  gh issue edit "$ISSUE_NUMBER" --repo "$REPO_OWNER/$REPO_NAME" --add-label "$SET_STATE_LABEL" >/dev/null
  issue_json="$(gh issue view "$ISSUE_NUMBER" --repo "$REPO_OWNER/$REPO_NAME" --json number,state,labels,title,milestone)"
fi

labels_csv="$(echo "$issue_json" | jq -r '[.labels[].name] | join(",")')"

pick_suffix () {
  local prefix="$1"
  local fallback="$2"
  local v
  v="$(echo "$labels_csv" | tr ',' '\n' | grep -E "^${prefix}" | head -n1 | sed "s/^${prefix}//")"
  if [[ -z "$v" ]]; then
    echo "$fallback"
  else
    echo "$v"
  fi
}

if [[ -z "$WORKFLOW_STATE" ]]; then
  if [[ "$issue_state" == "CLOSED" ]]; then
    WORKFLOW_STATE="Done"
  else
    state_suffix="$(pick_suffix 'state:' 'backlog')"
    case "$state_suffix" in
      backlog) WORKFLOW_STATE="Backlog" ;;
      ready) WORKFLOW_STATE="Ready" ;;
      in-progress) WORKFLOW_STATE="In Progress" ;;
      in-review) WORKFLOW_STATE="In Review" ;;
      verified) WORKFLOW_STATE="Verified" ;;
      done) WORKFLOW_STATE="Done" ;;
      *) WORKFLOW_STATE="Backlog" ;;
    esac
  fi
fi

priority_raw="$(pick_suffix 'priority:' 'p1')"
area_raw="$(pick_suffix 'area:' 'infra')"
risk_raw="$(pick_suffix 'risk:' 'medium')"

case "$priority_raw" in
  p0) PRIORITY="P0" ;;
  p1) PRIORITY="P1" ;;
  p2) PRIORITY="P2" ;;
  *) PRIORITY="P1" ;;
esac

case "$area_raw" in
  combat|ui|progression|data|test|infra) AREA="$area_raw" ;;
  *) AREA="infra" ;;
esac

case "$risk_raw" in
  low|medium|high) RISK="$risk_raw" ;;
  *) RISK="medium" ;;
esac

case "$WORKFLOW_STATE" in
  "In Progress") STATUS="In Progress" ;;
  "Verified"|"Done") STATUS="Done" ;;
  *) STATUS="Todo" ;;
esac

project_id="$(gh project view "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json --jq '.id')"
fields_json="$(gh project field-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --format json)"

field_id () {
  local name="$1"
  echo "$fields_json" | jq -r --arg n "$name" '.fields[] | select(.name==$n) | .id' | head -n1
}

option_id () {
  local field_name="$1"
  local option_name="$2"
  echo "$fields_json" | jq -r --arg f "$field_name" --arg o "$option_name" '.fields[] | select(.name==$f) | .options[] | select(.name==$o) | .id' | head -n1
}

wf_field="$(field_id 'Workflow State')"
status_field="$(field_id 'Status')"
priority_field="$(field_id 'Priority')"
area_field="$(field_id 'Area')"
risk_field="$(field_id 'Risk')"

wf_option="$(option_id 'Workflow State' "$WORKFLOW_STATE")"
status_option="$(option_id 'Status' "$STATUS")"
priority_option="$(option_id 'Priority' "$PRIORITY")"
area_option="$(option_id 'Area' "$AREA")"
risk_option="$(option_id 'Risk' "$RISK")"

issue_url="https://github.com/${REPO_OWNER}/${REPO_NAME}/issues/${ISSUE_NUMBER}"
item_id="$(gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --limit 200 --format json --jq ".items[] | select(.content.number==${ISSUE_NUMBER}) | .id" | head -n1)"
if [[ -z "$item_id" ]]; then
  item_id="$(gh project item-add "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --url "$issue_url" --format json --jq '.id')"
fi

apply_single_select () {
  local item="$1"
  local field="$2"
  local option="$3"
  if [[ -n "$field" && -n "$option" ]]; then
    gh project item-edit --id "$item" --project-id "$project_id" --field-id "$field" --single-select-option-id "$option" >/dev/null
  fi
}

apply_single_select "$item_id" "$wf_field" "$wf_option"
apply_single_select "$item_id" "$status_field" "$status_option"
apply_single_select "$item_id" "$priority_field" "$priority_option"
apply_single_select "$item_id" "$area_field" "$area_option"
apply_single_select "$item_id" "$risk_field" "$risk_option"

echo "Synced issue #${ISSUE_NUMBER}: Workflow=${WORKFLOW_STATE}, Status=${STATUS}, Priority=${PRIORITY}, Area=${AREA}, Risk=${RISK}"
