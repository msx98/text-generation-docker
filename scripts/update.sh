#!/usr/bin/env bash

echo "Updating Text Generation UI"
source /workspace/venv/bin/activate
cd /workspace/text-generation-webui
git checkout main
git pull
pip3 install -r requirements.txt
echo "Update complete"