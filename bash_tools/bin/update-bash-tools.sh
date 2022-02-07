#!/bin/bash

### Updates bash-tools.
###
### Usage:
###   update-bash-tools
###
### Options:
###   DRY_RUN: If set to anything, prints out DRY_RUN statements.

# Inpired by the `flock` man page to ensure this script is only running one
# at a time (ie: if multiple shells started before this completes)
#   https://unix.stackexchange.com/a/343270/15351
[[ "${FLOCKER}" != "$0" ]] && exec env FLOCKER="$0" flock -en "$0" "$0" "$@"

set -eo pipefail

BASH_TOOLS_URL='https://github.com/cjvirtucio87/bash-tools.git'
BASH_TOOLS_FILE="${HOME}/etc/bash-tools-version.txt"
INSTALL_DIR="${HOME}/lib/bash_tools"
SEMANTIC_NAME='install_bash_tools'
readonly BASH_TOOLS_URL BASH_TOOLS_FILE SEMANTIC_NAME

function ensure_latest_bash_tools_bash {
  local latest_version
  latest_version="$(git ls-remote \
    --tags "${BASH_TOOLS_URL}" \
    | cut --field 2 \
    | grep --extended-regexp 'refs/tags/bash-tools-([0-9]+\.[0-9]+\.[0-9]+)' \
    | sed --regexp-extended 's|refs/tags/bash-tools-([0-9]+\.[0-9]+\.[0-9]+)|\1|g' \
    | sort --version-sort \
    | tail -n 1)"

  if should_update "${latest_version}"; then
    install_bash_tools_bash "${latest_version}"
    setup_symlinks "${latest_version}"

    if ! [[ -v DRY_RUN ]]; then
      mkdir --parents "$(dirname "${BASH_TOOLS_FILE}")"
      echo -n "${latest_version}" | tee "${BASH_TOOLS_FILE}"
      echo ''
    fi
  fi
}

function install_bash_tools_bash {
  local latest_version="$1"
  local tarball_url="https://github.com/cjvirtucio87/bash-tools/releases/download/bash-tools-${latest_version}/cjvirtucio87-bash-tools-${latest_version}.tar.gz"
  local bash_tools_dir="${INSTALL_DIR}/bash-tools-${latest_version}"
  log "${SEMANTIC_NAME}" "cleaning up previous bash-tools folder"
  if ! [[ -v DRY_RUN ]]; then
    rm --recursive --force "${INSTALL_DIR:?}"
  fi

  log "${SEMANTIC_NAME}" "installing bash-tools at ${bash_tools_dir} from ${tarball_url}"
  if ! [[ -v DRY_RUN ]]; then
    mkdir --parents "${bash_tools_dir}"
    curl --fail --location "${tarball_url}" \
      | tar \
        --extract \
        --gunzip \
        --strip-components 1 \
        --directory "${bash_tools_dir}"

    chmod 755 "${bash_tools_dir}/bin"/*
  fi
}

function log {
  >&2 printf "%s %s: %s\n" "$(date +%H:%M:%S)" "$1" "$2"
}

function setup_symlinks {
  local latest_version="$1"
  local bash_tools_bin="${INSTALL_DIR}/bash-tools-${latest_version}/bin"
  log "${SEMANTIC_NAME}" "setting up symbolic links from ${HOME}/bin to ${bash_tools_bin}"

  local bash_tools=()
  while IFS=$'\n' read -r line; do
    bash_tools+=("${line}")
  done < <(ls "${bash_tools_bin}")

  for bash_tool in "${bash_tools[@]}"; do
    local home_bin_bash_tool
    home_bin_bash_tool="${HOME}/bin/$(basename "${bash_tool}")"

    if [[ -L "${home_bin_bash_tool}" ]]; then
      log "${SEMANTIC_NAME}" "removing old link ${home_bin_bash_tool}"
      if ! [[ -v DRY_RUN ]]; then
        unlink "${home_bin_bash_tool}"
      fi
    fi
  done

  for bash_tool in "${bash_tools[@]}"; do
    local local_bin_bash_tool
    local_bin_bash_tool="/usr/local/bin/$(basename "${bash_tool}")"

    log "${SEMANTIC_NAME}" "creating new link ${local_bin_bash_tool}"
    if ! [[ -v DRY_RUN ]]; then
      ln -s "${bash_tools_bin}/$(basename "${bash_tool}")" "${local_bin_bash_tool}"
    fi
  done
}

function should_update {
  local latest_version="$1"
  if ! diff <(printf '%s' "${latest_version}") "${BASH_TOOLS_FILE}" > /dev/null; then
    log "${SEMANTIC_NAME}" "version file content does not match latest version ${latest_version}"
    return
  fi

  if ! [[ -d "${INSTALL_DIR}/bash-tools-${latest_version}/bin" ]]; then
    log "${SEMANTIC_NAME}" "bash_tools install directory has not been created yet"
    return
  fi

  return 1
}

function main {
  log "${SEMANTIC_NAME}" "checking for bash-tools updates"
  ensure_latest_bash_tools_bash
  log "${SEMANTIC_NAME}" "updating tools complete"
}

main "$@"
