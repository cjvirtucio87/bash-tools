#!/usr/bin/env bash

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
