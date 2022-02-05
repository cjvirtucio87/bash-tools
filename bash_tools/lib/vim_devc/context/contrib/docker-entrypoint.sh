#!/usr/bin/env bash

set -e

function main {
  >&2 printf "running as [%s:%s]\n" "$(id --user)" "$(id --group)"
  exec /usr/bin/bash
}

main "$@"
