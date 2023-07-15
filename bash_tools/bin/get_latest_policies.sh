#!/usr/bin/env bash

function log {
  >&2 printf '[%s] %s\n' "$(date -I seconds)" "$1"
}

function main {
  set -eo pipefail

  local kind="$1"
  local name="$2"

  local attached_policy_arns=()
  local attached_policy_arn
  while read -r attached_policy_arn; do
    attached_policy_arns+=("${attached_policy_arn}")
  done < <(aws iam "list-attached-${kind}-policies" "--${kind}-name" "${name}" | jq -r '.AttachedPolicies[] | .PolicyArn')

  local latest_attached_policy_versions=()
  local latest_attached_policy_version
  for attached_policy_arn in "${attached_policy_arns[@]}"; do
    latest_attached_policy_version="$(aws iam list-policy-versions --policy-arn "${attached_policy_arn}" | jq -r '.Versions |= sort_by(.CreationDate) | .Versions[-1] | .VersionId')"
    echo "latest_attached_policy_version: ${latest_attached_policy_version}"
  done
}

main "$@"
