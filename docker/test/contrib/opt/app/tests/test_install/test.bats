#!/usr/bin/env bats
# shellcheck shell=bash

load "${TEST_SH_ROOT_DIR}/test-helper.bash"

readonly RESOURCES_DIR="${TEST_SH_ROOT_DIR}/test_install/resources"

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

function test_add_adds_directory { # @test
  init_dotfiles 'simple'
  _init_managed_dir
  _test_install
  _diff_repo_dest_dir

  local expected_dir='.foo'
  local dest_expected_dirpath="${DEST_DIR}/${expected_dir}"
  mkdir -p "${DEST_DIR}/${expected_dir}/bar"
  echo -n 'hello' > "${dest_expected_dirpath}/bar/hello.txt"
  stowsh add "${dest_expected_dirpath}"
  local actual_dir
  actual_dir="$(stowsh git status -s | grep ?? | cut -d' ' -f2 | tr --delete '\n')"

  printf 'expected [%s], got [%s]\n' "${expected_dir}/" "${actual_dir}"
  [[ "${expected_dir}/" == "${actual_dir}" ]]
  diff --unified "${dest_expected_dirpath}/" "${MANAGED_DIR}/${actual_dir}"
}

function test_add_adds_directory_to_subpath { # @test
  init_dotfiles 'subpath'
  _init_managed_dir
  _test_install
  _diff_repo_dest_dir

  local expected_dir='.foo'
  local expected_subpath='ubuntu'
  local dest_expected_dirpath="${DEST_DIR}/${expected_dir}"
  mkdir -p "${DEST_DIR}/${expected_dir}/bar"
  echo -n 'hello' > "${dest_expected_dirpath}/bar/hello.txt"
  stowsh add "${dest_expected_dirpath}" "${expected_subpath}"
  local actual_dir
  actual_dir="$(stowsh git status -s | grep ?? | cut -d' ' -f2 | tr --delete '\n')"

  printf 'expected [%s], got [%s]\n' "${expected_subpath}/${expected_dir}/" "${actual_dir}"
  [[ "${expected_subpath}/${expected_dir}/" == "${actual_dir}" ]]
  diff --unified "${dest_expected_dirpath}/" "${MANAGED_DIR}/${actual_dir}"
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

  printf 'expected [%s], got [%s]\n' "${expected_filename}" "${actual_filename}"
  [[ "${expected_filename}" == "${actual_filename}" ]]
  diff --unified "${dest_expected_filepath}" "${MANAGED_DIR}/${actual_filename}"
}

function test_add_adds_file_to_subpath { # @test
  init_dotfiles 'subpath'
  _init_managed_dir
  _test_install
  _diff_repo_dest_dir

  local expected_filename='.new_file'
  local dest_expected_filepath="${DEST_DIR}/${expected_filename}"
  echo -n 'hello' > "${dest_expected_filepath}"

  local expected_subpath='ubuntu'
  stowsh add "${dest_expected_filepath}" "${expected_subpath}"

  stowsh git status -s
  local actual_filename
  actual_filename="$(stowsh git status -s | grep ?? | cut -d' ' -f2 | tr --delete '\n')"

  printf 'expected [%s], got [%s]\n' "${expected_filename}" "${actual_filename}"
  [[ "${expected_subpath}/${expected_filename}" == "${actual_filename}" ]]
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
