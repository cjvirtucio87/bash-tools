#!/usr/bin/env bats
# shellcheck shell=bash

readonly RESOURCES_DIR="${TEST_SH_ROOT_DIR}/test_gitversion/resources"

function assert_version {
  local expected_version="$1"
  local actual_version
  if ! actual_version="$(gitversion)"; then
    >&2 echo "${actual_version}"
    >&2 echo "failed to retrieve version"
    return 1
  fi

  if [[ "${expected_version}" != "${actual_version}" ]]; then
    >&2 printf 'expected [%s], got [%s]' "${expected_version}" "${actual_version}"
    return 1
  fi
}

function git_new_commit {
  local rand_suffix
  rand_suffix="$(echo -n "${RANDOM}")"
  rand_filename="foo-${rand_suffix}.txt"
  echo -n 'hello world' > "${REPO_PATH}/${rand_filename}"
  git_temp_dotfiles add "${rand_filename}"
  git_temp_dotfiles commit -m 'new commit'
}

function git_temp_dotfiles {
  git -C "${TEMP_DIR}/dotfiles" "$@"
}

function init_dotfiles {
  local project="$1"
  local path="$2"
  git config --global user.email "test@mail.com"
  git config --global user.name "Test"

  local subpath=''
  if [[ -n "${path}" ]]; then
    subpath="/${path}"
  fi

  mkdir --parents "${TEMP_DIR}/dotfiles${subpath}"
  shopt -s dotglob
  cp -r "${RESOURCES_DIR}/${project}/git/dotfiles"/* "${TEMP_DIR}/dotfiles${subpath}"
  shopt -u dotglob
  git_temp_dotfiles init
  git_temp_dotfiles add -A
  git_temp_dotfiles commit -m "initial commit"

  REPO_PATH="${TEMP_DIR}/dotfiles"
  DOTFILES_URL="file://${REPO_PATH}"
}

function setup {
  TEMP_DIR="$(mktemp --directory --suffix '_test_install')"
}

function teardown {
  rm -rf "${TEMP_DIR:?}"
}

function test_version_prints_version { # @test
  init_dotfiles 'simple'
  cd "${REPO_PATH}"

  assert_version '1.0.0'

  git_new_commit
  assert_version '1.0.1'

  git_new_commit
  assert_version '1.0.2'

  echo -n 1.1 > "${REPO_PATH}/version.txt"
  git_temp_dotfiles add version.txt
  git commit -m 'bumped up minor'
  assert_version '1.1.0'

  git_new_commit
  assert_version '1.1.1'

  git_new_commit
  assert_version '1.1.2'
}
