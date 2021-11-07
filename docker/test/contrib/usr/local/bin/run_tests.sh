#!/usr/bin/env bash

set -e

function main {
  bats --recursive "${TEST_SH_ROOT_DIR}" "$@"
}

main "$@"
