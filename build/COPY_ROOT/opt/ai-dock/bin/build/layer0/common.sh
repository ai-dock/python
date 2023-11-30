#!/bin/bash

# Must exit and fail to build if any command fails
set -eo pipefail

main() {
    install_python
}

do_mamba_install() {
    $MAMBA_CREATE -n "$1" -c conda-forge python="$2"
}

install_python() {
    if [[ $PYTHON_VERSION != "all" ]]; then
        do_mamba_install "${PYTHON_MAMBA_NAME}" "${PYTHON_VERSION}"
    else
        # Multi Python
        do_mamba_install "python_27" "2.7"
        do_mamba_install "python_38" "3.8"
        do_mamba_install "python_39" "3.9"
        do_mamba_install "python_310" "3.10"
        do_mamba_install "python_311" "3.11"
        do_mamba_install "python_312" "3.12"
    fi
}

main "$@"; exit