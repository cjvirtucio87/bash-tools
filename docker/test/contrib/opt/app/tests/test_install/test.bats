#!/usr/bin/env bats
# shellcheck shell=bash

readonly RESOURCES_DIR="${TEST_SH_ROOT_DIR}/test_install/resources"

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

function _diff_repo_dest_dir {
  local path="$1"
  diff --exclude '.git' --recursive "${REPO_PATH}${path}" "${DEST_DIR}"
}

function _init_managed_dir {
  export MANAGED_DIR="${TEMP_DIR}/git/dotfiles"
}

function git_temp_dotfiles {
  git -C "${TEMP_DIR}/dotfiles" "$@"
}

function setup {
  TEMP_DIR="$(mktemp --directory --suffix '_test_install')"
}

function teardown {
  rm -rf "${TEMP_DIR:?}"
}

function test_add_adds_file { # @test
  init_dotfiles 'simple'
  _init_managed_dir
  _test_install
  _diff_repo_dest_dir

  local expected_filename='.new_file'
  local dest_expected_filepath="${DEST_DIR}/${expected_filename}"
  echo -n 'hello' > "${dest_expected_filepath}"
  stowsh add "${dest_expected_filepath}"
  local actual_filename
  actual_filename="$(stowsh git status -s | grep ?? | cut -d' ' -f2 | tr --delete '\n')"

  [[ "${expected_filename}" == "${actual_filename}" ]]
  diff --unified "${dest_expected_filepath}" "${MANAGED_DIR}/${actual_filename}"
}

function _test_install {
  local path="$1"

  if [[ -n "${path}" ]]; then
    path="/${path}"
  fi

  export DEST_DIR="${TEMP_DIR}/home"
  mkdir --parents "${DEST_DIR}"

  stowsh install "${DOTFILES_URL}" "${path}"
  _diff_repo_dest_dir "${path}"
}

function test_install_installs_dotfiles { # @test
  init_dotfiles 'simple'
  _init_managed_dir
  _test_install
}

function test_install_installs_dotfiles_subpath { # @test
  local path='ubuntu'
  init_dotfiles 'simple' "${path}"
  _init_managed_dir
  _test_install "${path}"
}

function test_install_installs_dotfiles_with_folders_subpath { # @test
  local path='ubuntu'
  init_dotfiles 'folders' "${path}"
  _init_managed_dir
  _test_install "${path}"
}
