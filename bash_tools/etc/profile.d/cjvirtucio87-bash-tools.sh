#!/usr/bin/env bash

INSTALL_DIR="${HOME}/lib/bash_tools"
readonly INSTALL_DIR

function ensure_attempt_install_daily {
  local today
  today="$(date '+%Y-%m-%d')"

  if ! diff <(echo -n "${today}") "${INSTALL_DIR}/today.txt" &>/dev/null; then
    >&2 echo 'no install attempts made for today; attempting install of dev-tools-bash'
    update-bash-tools
    echo -n "${today}" | sudo dd of="${INSTALL_DIR}/today.txt"
  fi
}

>&2 echo 'initializing dev-tools-bash'
ensure_attempt_install_daily
