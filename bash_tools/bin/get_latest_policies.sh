#!/usr/bin/env bash

### get_latest_policies.sh
###
### Helper script for retrieving latest AWS IAM policies for a resource.
###
### Usage:
###   get_latest_policies.sh <resource kind> <resource name>
###
### Arguments:
###   kind: the kind of resource whose policies will be retrieved (either role or user)
###   name: the name of resource whose policies will be retrieved
###
### Remarks:
###   Specify @me as the resource name to retrieve the policies for the current caller identity.

function log {
  >&2 printf '[%s] %s\n' "$(date -I seconds)" "$1"
}

function get_latest_attached_policy_versions {
  local kind="$1"
  local name="$2"

  local inline_policy_names=()
  local inline_policy_name
  while read -r inline_policy_name; do
    inline_policy_names+=("${inline_policy_name}")
  done < <(aws iam "list-${kind}-policies" "--${kind}-name" "${name}" | jq --raw-output --compact-output '.PolicyNames[]')

  local inline_policies=()
  local inline_policy_name
  for inline_policy_name in "${inline_policy_names[@]}"; do
    local inline_policy
    inline_policy="$(aws iam "get-${kind}-policy" "--${kind}-name" "${name}" --policy-name "${inline_policy_name}" | jq --raw-output --compact-output '.')"

    inline_policies+=("${inline_policy}")
  done

  local attached_policy_arns=()
  local attached_policy_arn
  while read -r attached_policy_arn; do
    attached_policy_arns+=("${attached_policy_arn}")
  done < <(aws iam "list-attached-${kind}-policies" "--${kind}-name" "${name}" | jq --raw-output --compact-output '.AttachedPolicies[] | .PolicyArn')

  local latest_attached_policy_versions=()
  local latest_attached_policy_version
  for attached_policy_arn in "${attached_policy_arns[@]}"; do
    latest_attached_policy_version="$(aws iam list-policy-versions --policy-arn "${attached_policy_arn}" | jq --raw-output --arg policy_arn "${attached_policy_arn}" '.Versions |= sort_by(.CreationDate) | .Versions[-1] | {PolicyArn: $policy_arn, VersionId: .VersionId}')"
    latest_attached_policy_versions+=("${latest_attached_policy_version}")
  done

  local latest_attached_policy_version_docs=()
  for latest_attached_policy_version in "${latest_attached_policy_versions[@]}"; do
    local policy_arn
    policy_arn="$(jq --raw-output '.PolicyArn' <<<"${latest_attached_policy_version}")"

    local version_id
    version_id="$(jq --raw-output '.VersionId' <<<"${latest_attached_policy_version}")"

    local latest_attached_policy_version_doc
    latest_attached_policy_version_doc="$(aws iam get-policy-version --policy-arn "${policy_arn}" --version-id "${version_id}" | jq --raw-output --compact-output --arg policy_arn "${policy_arn}" --arg version_id "${version_id}" '{PolicyArn: $policy_arn, VersionId: $version_id, PolicyVersion: .}')"

    latest_attached_policy_version_docs+=("${latest_attached_policy_version_doc}")
  done

  local assume_role_policy='{}'
  if [[ "${kind}" =~ role ]]; then
    assume_role_policy="$(aws iam get-role --role-name "${name}" | jq --raw-output --compact-output '.Role.AssumeRolePolicyDocument')"
  fi

  jq \
    --null-input \
    --arg resource_kind "${kind}" \
    --arg resource_name "${name}" \
    --argjson assume_role_policy "${assume_role_policy}" \
    --slurpfile inline_policies <(for inline_policy in "${inline_policies[*]}"; do echo "${inline_policy}"; done) \
    --slurpfile latest_attached_policy_version_docs <(for latest_attached_policy_versoin_doc in "${latest_attached_policy_version_docs[*]}"; do echo "${latest_attached_policy_versoin_doc}"; done) \
    "$(cat <<'EOF'
{
  ResourceKind: $resource_kind,
  ResourceName: $resource_name,
  AssumeRolePolicy: $assume_role_policy,
  InlinePolicies: $inline_policies,
  LatestAttachedPolicyVersions: $latest_attached_policy_version_docs
}
EOF
)"
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
