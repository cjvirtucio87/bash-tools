#!/usr/bin/env bash

function assume_role {
  local role_arn="$1"

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
  local args=("$@")

  local role_arn
  role_arn="$(aws iam get-role --role-name cjvautomation-android | jq --raw-output --compact-output '.Role.Arn')"

  assume_role "${role_arn}"

  aws "${args[@]}"
}

main "$@"
