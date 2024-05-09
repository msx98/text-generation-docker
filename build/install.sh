#!/usr/bin/env bash
set -e
# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install torch
source ~/.bashrc
uv venv -p 3.10 /venv
source /venv/bin/activate
uv pip install torch==${TORCH_VERSION} --index-url ${INDEX_URL}

# Clone the git repo of Text Generation Web UI and set version
git clone https://github.com/oobabooga/text-generation-webui
cd /text-generation-webui
git checkout ${OOBABOOGA_COMMIT}

# Install the dependencies for Text Generation Web UI
# Including all extensions
uv pip install -r requirements.txt
bash -c 'for req in extensions/*/requirements.txt ; do pip3 install -r "$req" ; done'
#    mkdir -p repositories
#    cd repositories
#    git clone https://github.com/turboderp/exllamav2
#    cd exllamav2
#    pip3 install -r requirements.txt
#    pip3 install .

# Fix safetensors module broken by above exllama repository installation
uv pip install -U safetensors>=0.4.1
