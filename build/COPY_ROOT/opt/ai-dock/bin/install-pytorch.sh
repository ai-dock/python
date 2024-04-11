#!/bin/bash

while getopts v: flag
do
    case "${flag}" in
        v) pytorch_version="$OPTARG";;
    esac
done

init() {
    if [[ -z $pytorch_version ]]; then
        printf "Usage: install-pytorch -v <version>\n"
        exit 1
    fi

    env_location="$(micromamba info | grep "env location" | awk '{print $4}')"

    if [[ -z $env_location || $env_location == "-" ]]; then
        printf "This command must be run in a micromamba environment\n"
        exit 1
    fi
    
    # Mamba will downgrade python to satisfy requirements. We don't want that.
    python_version="$(python -V | tail -n1 | awk '{print $2}' | cut -d '.' -f1,2)"
    
    [[ -n $python_version && -n $pytorch_version ]] || exit 1
    
    install_pytorch_common
    
    if [[ -n $CUDA_VERSION ]]; then
        install_pytorch_cuda $pytorch_version
    elif [[ -n $ROCM_VERSION ]]; then
        install_pytorch_rocm $pytorch_version
    else
        install_pytorch_cpu $pytorch_version
    fi
    
    printf "export LD_LIBRARY_PATH="%s/lib/python%s/site-packages/torch/lib:%s"\n" "$env_location" "$python_version" "$LD_LIBRARY_PATH" >> "${env_location}/etc/conda/activate.d/10_ld.sh"
}

install_pytorch_common() {
    if [[ $pytorch_version == "2.0.1" ]]; then
        ffmpeg_version="4.4"
    else
        ffmpeg_version="6.*"
    fi
    
    micromamba install -y \
        ffmpeg="$ffmpeg_version" \
        sox=14.4.2 \
        ocl-icd-system
}

install_pytorch_cuda() {
    printf "channels: [pytorch,nvidia,conda-forge]" > "${env_location}/.mambarc"

    micromamba install -y \
        pytorch=${pytorch_version} torchvision torchaudio \
        python=${python_version} \
        pytorch-cuda="$(cut -d '.' -f 1,2 <<< "${CUDA_VERSION}")"
}

install_pytorch_rocm() {
    # No additional channels added for ROCm torch

    micromamba install -c pytorch -y \
        pytorch=${pytorch_version} torchvision torchaudio \
        python=${python_version} \
        --only-deps
        
    # Now pip install...
    pip install \
        --no-cache-dir \
        --index-url https://download.pytorch.org/whl/rocm${ROCM_VERSION} \
        torch==${pytorch_version} torchvision torchaudio 
}

install_pytorch_cpu() {
    printf "channels: [pytorch,conda-forge]" > "${env_location}/.mambarc"

    micromamba install -y \
        python=${python_version} \
        pytorch=${pytorch_version} torchvision \
        torchaudio \
        cpuonly
}

init "$@"