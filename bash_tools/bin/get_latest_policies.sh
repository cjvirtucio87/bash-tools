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
    latest_attached_policy_version="$(aws iam list-policy-versions --policy-arn "${attached_policy_arn}" | jq --raw-output --arg policy_arn "${attached_policy_arn}" '.Versions |= sort_by(.CreationDate) | .Versions[-1] | {PolicyArn: $policy_arn, VersionId: .VersionId}')"
    latest_attached_policy_versions+=("${latest_attached_policy_version}")
  done

  for latest_attached_policy_version in "${latest_attached_policy_versions[@]}"; do
    local policy_arn
    policy_arn="$(jq -r '.PolicyArn' <<<"${latest_attached_policy_version}")"

    local version_id
    version_id="$(jq -r '.VersionId' <<<"${latest_attached_policy_version}")"

    aws iam get-policy-version --policy-arn "${policy_arn}" --version-id "${version_id}"
  done | jq --slurp --arg resource_kind "${kind}" --arg resource_name "${name}" '{ResourceKind: $resource_kind, ResourceName: $resource_name, PolicyVersions: .}'
}

main "$@"
