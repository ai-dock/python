#!/bin/false

source /opt/ai-dock/etc/environment.sh

build_common_main() {
    build_common_install_python
    rm /etc/ld.so.cache
    ldconfig
}

build_common_do_mamba_install() {
    $MAMBA_CREATE -n "$1" python="$2"
    printf "/opt/micromamba/envs/%s/lib\n" "$1" >> /etc/ld.so.conf.d/x86_64-linux-gnu.micromamba.80-python.conf
}

build_common_install_python() {
    if [[ $PYTHON_VERSION != "all" ]]; then
        build_common_do_mamba_install "${PYTHON_MAMBA_NAME}" "${PYTHON_VERSION}"
    else
        # Multi Python
        build_common_do_mamba_install "python_310" "3.10"
        build_common_do_mamba_install "python_311" "3.11"
        build_common_do_mamba_install "python_312" "3.12"
    fi
}

build_common_main "$@"