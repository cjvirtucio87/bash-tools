#!/usr/bin/env bash

set -e

### Build script. Builds the test container and runs the unit tests.
###
### Usage:
###   ./build.sh

ROOT_DIR="$(dirname "$(readlink --canonicalize "$0")")"
readonly ROOT_DIR
readonly TEST_IMAGE_TAG='cjvirtucio87/bash-tools-test:latest'

function main {
  docker build \
    --tag "${TEST_IMAGE_TAG}" \
    --file "${ROOT_DIR}/docker/test/Dockerfile" \
    .
}

main "$@"
