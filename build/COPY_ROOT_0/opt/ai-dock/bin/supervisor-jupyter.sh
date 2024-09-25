#!/bin/bash

trap cleanup EXIT

function cleanup() {
    kill $(jobs -p) > /dev/null 2>&1
    fuser -k -SIGTERM ${LISTEN_PORT}/tcp > /dev/null 2>&1 &
    rm /run/http_ports/$PROXY_PORT > /dev/null 2>&1
    wait -n
    if [[ -z "$VIRTUAL_ENV" ]]; then
        deactivate
    fi
}

function start() {
    source /opt/ai-dock/etc/environment.sh
    source /opt/ai-dock/bin/venv-set.sh serviceportal
    source /opt/ai-dock/bin/venv-set.sh jupyter
    set_kernel_paths


    LISTEN_PORT=18888
    METRICS_PORT=${JUPYTER_METRICS_PORT:-28888}
    SERVICE_URL="${JUPYTER_URL:-}"
    QUICKTUNNELS=true
    
    if [[ ! -v JUPYTER_PORT || -z $JUPYTER_PORT ]]; then
        JUPYTER_PORT=${JUPYTER_PORT_HOST:-8888}
    fi
    PROXY_PORT=$JUPYTER_PORT
    
    if [[ ! -v JUPYTER_MODE || -z $JUPYTER_MODE ]]; then
        JUPYTER_MODE=${JUPYTER_TYPE:-"notebook"}
    fi
    if [[ $JUPYTER_MODE != "notebook" ]]; then
        JUPYTER_MODE="lab"
    fi
    
    SERVICE_NAME="Jupyter ${JUPYTER_MODE^}"
    
    if [[ ${SERVERLESS,,} = "true" ]]; then
        printf "Refusing to start $SERVICE_NAME service in serverless mode\n"
        exec sleep 10
    fi
    
    file_content="$(
      jq --null-input \
        --arg listen_port "${LISTEN_PORT}" \
        --arg metrics_port "${METRICS_PORT}" \
        --arg proxy_port "${PROXY_PORT}" \
        --arg proxy_secure "${PROXY_SECURE,,}" \
        --arg service_name "${SERVICE_NAME}" \
        --arg service_url "${SERVICE_URL}" \
        '$ARGS.named'
    )"
    
    printf "%s" "$file_content" > /run/http_ports/$PROXY_PORT
    
    # Delay launch until micromamba is ready
    if [[ -f /run/workspace_sync ]]; then
        printf "Waiting for workspace sync...\n"
        "$SERVICEPORTAL_VENV_PYTHON" /opt/ai-dock/fastapi/logviewer/main.py \
            -p $LISTEN_PORT \
            -r 3 \
            -s "${SERVICE_NAME}" \
            -t "Preparing ${SERVICE_NAME}" &
        fastapi_pid=$!
        
        while [[ -f /run/workspace_sync ]]; do
            sleep 1
        done
        
        kill $fastapi_pid &
        wait -n
    fi
    
    fuser -k -SIGKILL ${LISTEN_PORT}/tcp > /dev/null 2>&1 &
    wait -n
    
    # Allows running in user context when the home directory has non-standard permissions
    if [[ $WORKSPACE_MOUNTED == "true" && $WORKSPACE_PERMISSIONS == "false" ]]; then
        export JUPYTER_ALLOW_INSECURE_WRITES=true
    fi

    printf "\nStarting %s...\n" "${SERVICE_NAME:-service}"

    source "$JUPYTER_VENV/bin/activate"
    nvm use default
    jupyter "$JUPYTER_MODE" \
        --allow-root \
        --ip=127.0.0.1 \
        --port=$LISTEN_PORT \
        --no-browser \
        --ServerApp.token='' \
        --ServerApp.password='' \
        --ServerApp.trust_xheaders=True \
        --ServerApp.disable_check_xsrf=False \
        --ServerApp.allow_remote_access=True \
        --ServerApp.allow_origin='*' \
        --ServerApp.allow_credentials=True \
        --ServerApp.root_dir=/ \
        --ServerApp.preferred_dir="$WORKSPACE" \
        --KernelSpecManager.ensure_native_kernel=False
}

function set_kernel_paths() {
    # Define the base directories
    workspace_dir="${WORKSPACE}environments/python"
    jupyter_kernels_dir="/usr/local/share/jupyter/kernels"

    # Loop over each directory in the workspace
    for dir in "$workspace_dir"/*; do
        if [ -d "$dir" ]; then
            # Extract the directory name
            dir_name=$(basename "$dir")

            # Define the search and replacement strings
            search_string="/opt/environments/python/$dir_name"
            replace_string="${WORKSPACE}environments/python/$dir_name"

            # Recursively perform the sed replacement in the jupyter kernels directory
            find "$jupyter_kernels_dir" -type f -exec sudo sed -i "s|$search_string|$replace_string|g" {} +

            echo "Replaced '$search_string' with '$replace_string' in $jupyter_kernels_dir"
        fi
    done
}

start 2>&1
