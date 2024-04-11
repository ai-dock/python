#!/bin/false

source /opt/ai-dock/etc/environment.sh

kernel_path=/usr/local/share/jupyter/kernels/

build_common_main() {
    build_common_install_python
    build_common_install_jupyter
    build_common_install_ipykernel
}

build_common_do_mamba_install_python() {
    micromamba create -n "$1"
    micromamba run -n "$1" mamba-skel
    micromamba install -n "$1" -y python="$2" nano
}

build_common_install_python() {
    if [[ $PYTHON_VERSION != "all" ]]; then
        build_common_do_mamba_install_python "${PYTHON_MAMBA_NAME}" "${PYTHON_VERSION}"
    else
        # Multi Python
        build_common_do_mamba_install_python "python_310" "3.10"
        build_common_do_mamba_install_python "python_311" "3.11"
        build_common_do_mamba_install_python "python_312" "3.12"
    fi
}

build_common_install_jupyter() {
    micromamba create -n jupyter
    micromamba run -n jupyter mamba-skel
    micromamba install -n jupyter -y \
        jupyter \
        jupyterlab \
        nodejs=20 \
        python=3.10
    
    # This must remain clean. User software should not be in this environment
    printf "Removing default ipython kernel...\n"
    rm -rf /opt/micromamba/envs/jupyter/share/jupyter/kernels/python3
}

build_common_do_mamba_install_ipykernel() {
        micromamba install -n "$1" -y \
            ipykernel \
            ipywidgets
}

build_common_do_kernel_install() {
    if [[ -n $4 ]]; then
        # Add a clone, probably the often-present Python3 (ipykernel) pointed to our default python install
        dir="${kernel_path}${3}/"
        file="${dir}kernel.json"
        cp -rf ${kernel_path}../_template ${dir}
            
        sed -i 's/DISPLAY_NAME/'"$4"'/g' ${file}
        sed -i 's/PYTHON_MAMBA_NAME/'"$1"'/g' ${file}
    fi
    dir="${kernel_path}$1/"
    file="${dir}kernel.json"
    cp -rf ${kernel_path}../_template ${dir}
    
    sed -i 's/DISPLAY_NAME/'"Python $2"'/g' ${file}
    sed -i 's/PYTHON_MAMBA_NAME/'"$1"'/g' ${file}
}

build_common_install_ipykernel() {
    if [[ $PYTHON_VERSION != "all" ]]; then
        major=${PYTHON_VERSION:0:1}
        build_common_do_mamba_install_ipykernel "${PYTHON_MAMBA_NAME}"
        build_common_do_kernel_install "${PYTHON_MAMBA_NAME}" "${PYTHON_VERSION}" "python${major}" "Python${major} (ipykernel)"
    else
        # Multi Python - Use $PYTHON_MAMBA_NAME as default kernel
        
        build_common_do_mamba_install_ipykernel "python_310"
        if [[ $PYTHON_MAMBA_NAME = "python_310" ]]; then
            build_common_do_kernel_install "python_310" "3.10" "python3" "Python3 (ipykernel)"
        else
            build_common_do_kernel_install "python_310" "3.10"
        fi
        
        build_common_do_mamba_install_ipykernel "python_311"
        if [[ $PYTHON_MAMBA_NAME = "python_311" ]]; then
            build_common_do_kernel_install "python_311" "3.11" "python3" "Python3 (ipykernel)"
        else
            build_common_do_kernel_install "python_311" "3.11"
        fi
        
        build_common_do_mamba_install_ipykernel "python_312"
        if [[ $PYTHON_MAMBA_NAME = "python_312" ]]; then
            build_common_do_kernel_install "python_312" "3.12" "python3" "Python3 (ipykernel)"
        else
            build_common_do_kernel_install "python_312" "3.12"
        fi
    fi
}

build_common_main "$@"