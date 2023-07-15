#!/usr/bin/env bash

### get_latest_policies.sh
###
### Helper script for retrieving latest AWS IAM policies for a resource.
###
### Specify @me as the resource name to retrieve the policies for the current caller identity.

function log {
  >&2 printf '[%s] %s\n' "$(date -I seconds)" "$1"
}

function get_latest_attached_policy_versions {
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

function get_self_latest_policy_versions {
  local kind="$1"

  local caller_arn
  caller_arn="$(aws sts get-caller-identity | jq --raw-output '.Arn')"

  local caller_resource_name
  case "${kind}" in
    role)
      caller_resource_name="$(cut -d '/' -f2 <<<"${caller_arn}")"
      ;;
    user)
      caller_resource_name="$(basename "${caller_arn}")"
      ;;
  esac

  get_latest_attached_policy_versions "${kind}" "${caller_resource_name}"
}

function main {
  set -eo pipefail

  local kind="$1"
  local name="$2"

  if [[ "${name}" == '@me' ]]; then
    get_self_latest_policy_versions "${kind}"
    return
  fi

  get_latest_attached_policy_versions "${kind}" "${name}"
}

main "$@"
