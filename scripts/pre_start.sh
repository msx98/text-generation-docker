#!/usr/bin/env bash

export PYTHONUNBUFFERED=1
export APP="text-generation-webui"
DOCKER_IMAGE_VERSION_FILE="/workspace/${APP}/docker_image_version"

echo "Template version: ${TEMPLATE_VERSION}"
echo "venv: ${VENV_PATH}"

if [[ -e ${DOCKER_IMAGE_VERSION_FILE} ]]; then
    EXISTING_VERSION=$(cat ${DOCKER_IMAGE_VERSION_FILE})
else
    EXISTING_VERSION="0.0.0"
fi

rsync_with_progress() {
    stdbuf -i0 -o0 -e0 rsync -au --info=progress2 "$@" | stdbuf -i0 -o0 -e0 tr '\r' '\n' | stdbuf -i0 -o0 -e0 grep -oP '\d+%|\d+.\d+[mMgG]' | tqdm --bar-format='{l_bar}{bar}' --total=100 --unit='%' > /dev/null
}

sync_apps() {
    # Only sync if the DISABLE_SYNC environment variable is not set
    if [ -z "${DISABLE_SYNC}" ]; then
        # Sync venv to workspace to support Network volumes
        echo "Syncing venv to workspace, please wait..."
        rsync_with_progress --remove-source-files /venv/ ${VENV_PATH}/

        # Sync application to workspace to support Network volumes
        echo "Syncing ${APP} to workspace, please wait..."
        rsync_with_progress --remove-source-files /${APP}/ /workspace/${APP}/

        echo "${TEMPLATE_VERSION}" > ${DOCKER_IMAGE_VERSION_FILE}
        echo "${VENV_PATH}" > "/workspace/${APP}/venv_path"
    fi
}

fix_venvs() {
    # Fix the venv to make it work from VENV_PATH
    echo "Fixing venv..."
    /fix_venv.sh /venv ${VENV_PATH}
}

if [ "$(printf '%s\n' "$EXISTING_VERSION" "$TEMPLATE_VERSION" | sort -V | head -n 1)" = "$EXISTING_VERSION" ]; then
    if [ "$EXISTING_VERSION" != "$TEMPLATE_VERSION" ]; then
        sync_apps
        fix_venvs

        # Create directories
        mkdir -p /workspace/logs /workspace/tmp
    else
        echo "Existing version is the same as the template version, no syncing required."
    fi
else
    echo "Existing version is newer than the template version, not syncing!"
fi

if [[ ${MODEL} ]];
then
    if [[ ! -e "/workspace/text-gen-model" ]];
    then
        echo "Downloading model (${MODEL}), this could take some time, please wait..."
        source /workspace/venv/bin/activate
        /workspace/text-generation-webui/fetch_model.py "${MODEL}" /workspace/text-generation-webui/models >> /workspace/logs/download-model.log 2>&1
        deactivate
    fi
fi

if [[ ${DISABLE_AUTOLAUNCH} ]];
then
    echo "Auto launching is disabled so the application will not be started automatically"
    echo "You can launch it manually:"
    echo ""
    echo "   cd /workspace/text-generation-webui"
    echo "   ./start_textgen_server.sh"
else
    ARGS=()

    if [[ ${UI_ARGS} ]];
    then
    	  ARGS=("${ARGS[@]}" ${UI_ARGS})
    fi

    echo "Starting Oobabooga Text Generation Web UI"
    cd /workspace/text-generation-webui
    nohup ./start_textgen_server.sh "${ARGS[@]}" > /workspace/logs/textgen.log 2>&1 &
    echo "Oobabooga Text Generation Web UI started"
    echo "Log file: /workspace/logs/textgen.log"
fi

echo "All services have been started"
