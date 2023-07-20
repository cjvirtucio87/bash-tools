#!/usr/bin/env bash

function assume_role {
  local role_name="$1"

  local role_arn
  role_arn="$(aws iam get-role --role-name "${role_name}" | jq --raw-output --compact-output '.Role.Arn')"

  local current_user
  current_user="$(whoami)"

  local json
  json="$(aws sts assume-role --role-arn "${role_arn}" --role-session-name "${current_user}-assume-exec" | jq --raw-output --compact-output)"

  AWS_ACCESS_KEY_ID="$(jq --raw-output '.Credentials.AccessKeyId' <<<"${json}")"
  AWS_SECRET_ACCESS_KEY="$(jq --raw-output '.Credentials.SecretAccessKey' <<<"${json}")"
  AWS_SESSION_TOKEN="$(jq --raw-output '.Credentials.SessionToken' <<<"${json}")"

  export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
}

function main {
  set -eo pipefail

  local role_name="$1"
  local all_args=("$@")
  local all_args_count="${#all_args}"

  let "offset_args_count = all_args_count - 1"

  local args=("${all_args[@]:1:${offset_args_count}}")
  assume_role "${role_name}"

  aws "${args[@]}"
}

if (return 0 2>/dev/null); then
  assume_role "$1"
  return
fi

main "$@"
