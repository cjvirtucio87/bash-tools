FROM rockylinux/rockylinux

USER 0

ENV BATS_VERSION='1.3.0' \
    BATS_DIR=/usr/local/bats \
    TEST_SH_ROOT_DIR=/opt/app/tests

RUN set -e; \
    dnf update -y; \
    dnf install git -y; \
    TEMP_DIR="$(mktemp --directory)"; \
    curl \
      --location \
      "https://github.com/bats-core/bats-core/archive/refs/tags/v${BATS_VERSION}.tar.gz" \
      | tar \
        --gunzip \
        --extract \
        --directory "${TEMP_DIR}" \
        --strip-components 1; \
    mkdir --parents "${BATS_DIR}"; \
    "${TEMP_DIR}/install.sh" "${BATS_DIR}"; \
    chmod 755 "${BATS_DIR}/bin"/*; \
    ln -s "${BATS_DIR}/bin/bats" /usr/local/bin/bats; \
    rm -rf "${TEMP_DIR}"; \
    : ;

COPY bash_tools /usr/local/

COPY docker/test/contrib /

RUN set -e; \
    chgrp -R 0 "${TEST_SH_ROOT_DIR}"; \
    chmod g=u "${TEST_SH_ROOT_DIR}"; \
    : ;

RUN /usr/local/bin/run_tests.sh
