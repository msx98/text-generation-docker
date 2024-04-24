ARG BASE_IMAGE
FROM ${BASE_IMAGE}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash \
    PATH="/usr/local/cuda/bin:${PATH}"

# Install Torch
ARG INDEX_URL
ARG TORCH_VERSION
WORKDIR /
RUN python3 -m venv --system-site-packages /venv && \
    source /venv/bin/activate && \
    pip3 install torch==${TORCH_VERSION} --index-url ${INDEX_URL} && \
    deactivate

# Clone the git repo of Text Generation Web UI and set version
ARG OOBABOOGA_COMMIT
RUN git clone https://github.com/oobabooga/text-generation-webui && \
    cd /text-generation-webui && \
    git checkout ${OOBABOOGA_COMMIT}

# Install the dependencies for Text Generation Web UI
# Including all extensions
WORKDIR /text-generation-webui
#COPY oobabooga/requirements* ./
RUN source /venv/bin/activate && \
    pip3 install -r requirements.txt && \
    bash -c 'for req in extensions/*/requirements.txt ; do pip3 install -r "$req" ; done' && \
#    mkdir -p repositories && \
#    cd repositories && \
#    git clone https://github.com/turboderp/exllamav2 && \
#    cd exllamav2 && \
#    pip3 install -r requirements.txt && \
#    pip3 install . && \
    deactivate

# Fix safetensors module broken by above exllama repository installation
RUN source /venv/bin/activate && \
    pip3 install -U safetensors>=0.4.1 && \
    deactivate

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/api.html /usr/share/nginx/html/

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# Copy startup script for Oobabooba Web UI
COPY --chmod=755 scripts/start_textgen_server.sh /text-generation-webui/

# Copy scripts to download models
COPY fetch_model.py /text-generation-webui/
COPY download_model.py /text-generation-webui/

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Set the venv path
ARG VENV_PATH
ENV VENV_PATH=${VENV_PATH}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* ./

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
