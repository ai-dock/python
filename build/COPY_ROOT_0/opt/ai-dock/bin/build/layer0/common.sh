#!/bin/false

source /opt/ai-dock/etc/environment.sh

build_common_main() {
    build_common_install_python
    build_common_install_jupyter
}

build_common_do_install_python_venv() {
    $APT_INSTALL \
        "python${2}" \
        "python${2}-dev" \
        "python${2}-venv"
        
    venv="${VENV_DIR}/${1}"
    "python${2}" -m venv "$venv"
    
    "$venv/bin/pip" install --no-cache-dir \
        ipykernel \
        ipywidgets
        
    "$venv/bin/python" -m ipykernel install \
        --name="$1" \
        --display-name="Python$2 ($1)"
}

build_common_install_python() {
    if [[ $PYTHON_VERSION != "all" ]]; then
        build_common_do_install_python_venv "${PYTHON_VENV_NAME}" "${PYTHON_VERSION}"
    else
        # Multi Python
        build_common_do_install_python_venv "python_310" "3.10"
        build_common_do_install_python_venv "python_311" "3.11"
        build_common_do_install_python_venv "python_312" "3.12"
    fi
}

build_common_install_jupyter() {
    $APT_INSTALL \
        python3.10 \
        python3.10-dev \
        python3.10-venv
    venv="$VENV_DIR/jupyter"
    python3.10 -m venv "$venv"
    nvm use node
    "$venv/bin/pip" install --no-cache-dir \
        jupyterlab \
        notebook
    
    printf "Removing default ipython kernel...\n"
    rm -rf "$VENV_DIR/jupyter/share/jupyter/kernels/python3"
}

build_common_main "$@"