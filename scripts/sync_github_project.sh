#!/usr/bin/env bash
set -Eeuo pipefail

OWNER="scrimshawlife-ctrl"
REPOSITORY="scrimshawlife-ctrl/Waykin"
PROJECT_NUMBER="1"
PROJECT_TITLE="Waykin — Agent Execution"
MODE=""
PROJECT_ID=""
FIELDS_JSON='{}'
ITEMS_JSON='{}'
ITEM_ID=""
DRIFT=0
CHANGES=0

usage() {
  echo "Usage: $0 --check|--apply"
  echo "Requires authenticated gh access with project and repo scopes, plus jq."
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || { echo "ERROR missing command: $1" >&2; exit 2; }
}

verify_auth() {
  local login
  gh auth status >/dev/null
  login="$(gh api user --jq .login)"
  [[ "$login" == "$OWNER" ]] || { echo "ERROR authenticated as $login, expected $OWNER" >&2; exit 2; }
}

resolve_project() {
  local project
  project="$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json)"
  [[ "$(jq -r .number <<<"$project")" == "$PROJECT_NUMBER" ]] || { echo "ERROR project number mismatch" >&2; exit 2; }
  [[ "$(jq -r .title <<<"$project")" == "$PROJECT_TITLE" ]] || { echo "ERROR project title mismatch" >&2; exit 2; }
  [[ "$(jq -r .owner.login <<<"$project")" == "$OWNER" ]] || { echo "ERROR project owner mismatch" >&2; exit 2; }
  PROJECT_ID="$(jq -r .id <<<"$project")"
}

list_fields() {
  FIELDS_JSON="$(gh project field-list "$PROJECT_NUMBER" --owner "$OWNER" --limit 100 --format json)"
}

field_id() {
  jq -r --arg name "$1" '.fields[] | select(.name == $name) | .id' <<<"$FIELDS_JSON" | head -n 1
}

option_id() {
  local name="$1" option="$2"
  jq -r --arg name "$name" --arg option "$option" \
    '.fields[] | select(.name == $name) | .options[]? | select(.name == $option) | .id' \
    <<<"$FIELDS_JSON" | head -n 1
}

record_drift() {
  echo "DRIFT $1"
  DRIFT=$((DRIFT + 1))
}

ensure_text_field() {
  local name="$1" id type
  id="$(field_id "$name")"
  if [[ -z "$id" ]]; then
    if [[ "$MODE" == "apply" ]]; then
      gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" --name "$name" --data-type TEXT >/dev/null
      echo "APPLIED create text field: $name"
      CHANGES=$((CHANGES + 1))
      list_fields
    else
      record_drift "missing text field: $name"
    fi
    return
  fi
  type="$(jq -r --arg name "$name" '.fields[] | select(.name == $name) | .type' <<<"$FIELDS_JSON")"
  [[ "$type" == "ProjectV2Field" ]] || record_drift "field type mismatch: $name ($type)"
}

ensure_select_field() {
  local name="$1" expected_csv="$2" id type actual expected
  id="$(field_id "$name")"
  if [[ -z "$id" ]]; then
    if [[ "$MODE" == "apply" ]]; then
      gh project field-create "$PROJECT_NUMBER" --owner "$OWNER" --name "$name" \
        --data-type SINGLE_SELECT --single-select-options "$expected_csv" >/dev/null
      echo "APPLIED create select field: $name"
      CHANGES=$((CHANGES + 1))
      list_fields
    else
      record_drift "missing select field: $name"
    fi
    return
  fi
  type="$(jq -r --arg name "$name" '.fields[] | select(.name == $name) | .type' <<<"$FIELDS_JSON")"
  [[ "$type" == "ProjectV2SingleSelectField" ]] || { record_drift "field type mismatch: $name ($type)"; return; }
  actual="$(jq -r --arg name "$name" '.fields[] | select(.name == $name) | [.options[].name] | join(",")' <<<"$FIELDS_JSON")"
  expected="$expected_csv"
  [[ "$actual" == "$expected" ]] || record_drift "select options require manual repair: $name expected=[$expected] actual=[$actual]"
}

refresh_items() {
  ITEMS_JSON="$(gh project item-list "$PROJECT_NUMBER" --owner "$OWNER" --limit 200 --format json)"
}

find_project_item() {
  local type="$1" number="$2"
  jq -r --arg type "$type" --argjson number "$number" \
    '.items[] | select(.content.type == $type and .content.number == $number) | .id' \
    <<<"$ITEMS_JSON" | head -n 1
}

content_url() {
  local type="$1" number="$2"
  if [[ "$type" == "Issue" ]]; then
    echo "https://github.com/$REPOSITORY/issues/$number"
  else
    echo "https://github.com/$REPOSITORY/pull/$number"
  fi
}

ensure_project_item() {
  local type="$1" number="$2" id
  id="$(find_project_item "$type" "$number")"
  if [[ -z "$id" ]]; then
    if [[ "$MODE" == "apply" ]]; then
      gh project item-add "$PROJECT_NUMBER" --owner "$OWNER" --url "$(content_url "$type" "$number")" >/dev/null
      echo "APPLIED add item: $type #$number"
      CHANGES=$((CHANGES + 1))
      refresh_items
      id="$(find_project_item "$type" "$number")"
    else
      record_drift "missing item: $type #$number"
    fi
  fi
  ITEM_ID="$id"
}

item_value() {
  local item_id="$1" field="$2" field_lower
  field_lower="$(printf '%s' "$field" | tr '[:upper:]' '[:lower:]')"
  jq -r --arg id "$item_id" --arg field "$field_lower" \
    '.items[] | select(.id == $id) | to_entries[] | select((.key | ascii_downcase) == $field) | .value // ""' \
    <<<"$ITEMS_JSON" | head -n 1
}

set_text_value() {
  local item_id="$1" field="$2" expected="$3" current fid
  [[ -n "$item_id" ]] || return
  if [[ ( "$field" == "Base SHA" || "$field" == "Head SHA" ) && -z "$expected" ]]; then
    return
  fi
  current="$(item_value "$item_id" "$field")"
  [[ "$current" == "$expected" ]] && return
  if [[ "$MODE" == "apply" ]]; then
    fid="$(field_id "$field")"
    [[ -n "$fid" ]] || { record_drift "cannot set missing field: $field"; return; }
    gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" --field-id "$fid" --text "$expected" >/dev/null
    echo "APPLIED set $field: $expected"
    CHANGES=$((CHANGES + 1))
  else
    record_drift "value mismatch item=$item_id field=$field expected=[$expected] actual=[$current]"
  fi
}

set_select_value() {
  local item_id="$1" field="$2" expected="$3" current fid oid
  [[ -n "$item_id" ]] || return
  current="$(item_value "$item_id" "$field")"
  [[ "$current" == "$expected" ]] && return
  if [[ "$MODE" == "apply" ]]; then
    fid="$(field_id "$field")"
    oid="$(option_id "$field" "$expected")"
    [[ -n "$fid" && -n "$oid" ]] || { record_drift "cannot resolve option: $field=$expected"; return; }
    gh project item-edit --id "$item_id" --project-id "$PROJECT_ID" --field-id "$fid" --single-select-option-id "$oid" >/dev/null
    echo "APPLIED set $field: $expected"
    CHANGES=$((CHANGES + 1))
  else
    record_drift "value mismatch item=$item_id field=$field expected=[$expected] actual=[$current]"
  fi
}

sync_item() {
  local type="$1" number="$2" status="$3" workstream="$4" agent="$5" lane="$6"
  local priority="$7" risk="$8" dependency="$9" handoff="${10}" evidence="${11}" item_id
  ensure_project_item "$type" "$number"
  item_id="$ITEM_ID"
  set_select_value "$item_id" "Execution Status" "$status"
  set_select_value "$item_id" "Workstream" "$workstream"
  set_text_value "$item_id" "Agent" "$agent"
  set_select_value "$item_id" "Agent Lane" "$lane"
  set_select_value "$item_id" "Priority" "$priority"
  set_select_value "$item_id" "Risk" "$risk"
  set_text_value "$item_id" "Dependency" "$dependency"
  set_select_value "$item_id" "Handoff State" "$handoff"
  set_select_value "$item_id" "Evidence" "$evidence"
}

sync_initial_items() {
  sync_item Issue 42 Review "AR Presentation" UNASSIGNED IMPLEMENT P0 High \
    "PR #40 merged; implementation PR #45" NONE PARTIAL
  sync_item PullRequest 45 Review "AR Presentation" UNASSIGNED REVIEW P0 High \
    "Issue #42" NONE PARTIAL
  sync_item Issue 46 Blocked Validation UNASSIGNED TEST P1 Medium \
    "PR #45 must merge" NONE NOT_STARTED
  sync_item Issue 41 Ready Validation UNASSIGNED DEVICE P1 High \
    "PR #40 merged" NONE NOT_STARTED
  sync_item Issue 47 "In Progress" Governance scrimshawlife-ctrl GOVERNANCE P0 Medium \
    NONE NONE PARTIAL
  if [[ "$MODE" == "apply" ]]; then
    refresh_items
  fi
}

print_receipt() {
  echo "RECEIPT mode=$MODE owner=$OWNER project=$PROJECT_NUMBER project_id=$PROJECT_ID"
  echo "RECEIPT fields=$(jq '.fields | length' <<<"$FIELDS_JSON") items=$(jq '.items | length' <<<"$ITEMS_JSON") changes=$CHANGES drift=$DRIFT"
  if [[ "$DRIFT" -eq 0 ]]; then
    echo "PROJECT_COORDINATION=ALIGNED"
  else
    echo "PROJECT_COORDINATION=DRIFTED"
  fi
}

main() {
  [[ $# -eq 1 && ( "$1" == "--check" || "$1" == "--apply" ) ]] || { usage; exit 2; }
  MODE="${1#--}"
  require_command gh
  require_command jq
  verify_auth
  resolve_project
  list_fields
  ensure_select_field "Execution Status" "Intake,Ready,Claimed,In Progress,Review,Validation,Blocked,Done"
  ensure_select_field "Workstream" "Core Runtime,AR Presentation,Audio,Movement,Persistence,Validation,Tooling,Documentation,Governance"
  ensure_text_field "Agent"
  ensure_select_field "Agent Lane" "IMPLEMENT,REVIEW,TEST,DOCS,DEVICE,GOVERNANCE"
  ensure_select_field "Priority" "P0,P1,P2,P3"
  ensure_select_field "Risk" "Low,Medium,High"
  ensure_text_field "Dependency"
  ensure_text_field "Base SHA"
  ensure_text_field "Head SHA"
  ensure_select_field "Handoff State" "NONE,REQUESTED,READY,ACCEPTED,REJECTED"
  ensure_select_field "Evidence" "NOT_STARTED,PARTIAL,PASS,FAIL,NOT_COMPUTABLE"
  refresh_items
  sync_initial_items
  print_receipt
  [[ "$DRIFT" -eq 0 ]]
}

main "$@"
