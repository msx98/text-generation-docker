#!/usr/bin/env bash

ARGS=("$@" --listen --api --listen-port 3001 --api-port 5001 --api-blocking-port 6050 --api-streaming-port 6055 --extensions openai)

if [[ -f /workspace/text-gen-model ]];
then
  ARGS=("${ARGS[@]}" --model "$(</workspace/text-gen-model)")
fi

source /workspace/venv/bin/activate
cd /workspace/text-generation-webui
echo "Starting Oobabooba Text Generation UI: ${ARGS[@]}"
python3 server.py "${ARGS[@]}"