# Docker image for the Text Generation Web UI: A Gradio web UI for Large Language Models. Supports transformers, GPTQ, llama.cpp (GGUF), Llama models

> [!NOTE]
> The legacy APIs no longer work with the latest version of the
> Text Generation Web UI. They were deprecated in
> November 2023 and have now been completely removed.
> If you want to use the LEGACY APIs, please set the image tag
> to `1.9.5`.  You will also have to add port 6000 for the
> legacy REST API and/or port 6005 for the legacy Websockets API.

## Installs

* Ubuntu 22.04 LTS
* CUDA 12.1.1
* Python 3.10.12
* [Text Generation Web UI](
  https://github.com/oobabooga/text-generation-webui)
* Torch 2.2.0
* xformers 0.0.24
* Jupyter Lab
* [runpodctl](https://github.com/runpod/runpodctl)
* [OhMyRunPod](https://github.com/kodxana/OhMyRunPod)
* [RunPod File Uploader](https://github.com/kodxana/RunPod-FilleUploader)
* [croc](https://github.com/schollz/croc)
* [rclone](https://rclone.org/)
* speedtest-cli
* screen
* tmux

## Available on RunPod

This image is designed to work on [RunPod](https://runpod.io?ref=2xxro4sy).
You can use my custom [RunPod template](
https://runpod.io/gsc?template=el5m58e1to&ref=2xxro4sy)
to launch it on RunPod.

## Building the Docker image

> [!NOTE]
> You will need to edit the `docker-bake.hcl` file and update `RELEASE`,
> and `tags`.  You can obviously edit the other values too, but these
> are the most important ones.

```bash
# Clone the repo
git clone https://github.com/ashleykleynhans/text-generation-docker.git

# Log in to Docker Hub
docker login

# Build the image, tag the image, and push the image to Docker Hub
cd text-generation-docker
docker buildx bake -f docker-bake.hcl --push
```

## Running Locally

### Install Nvidia CUDA Driver

- [Linux](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html)
- [Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/index.html)

### Start the Docker container

```bash
docker run -d \
  --gpus all \
  -v /workspace \
  -p 3000:3001 \
  -p 5000:5001 \
  -p 8888:8888 \
  -p 2999:2999 \
  -e VENV_PATH="/workspace/venvs/text-generation-webui" \
  ashleykza/oobabooga:latest
```

You can obviously substitute the image name and tag with your own.

## Ports

| Connect Port | Internal Port | Description            |
|--------------|---------------|------------------------|
| 3000         | 3001          | Text Generation Web UI |
| 5000         | 5001          | Open AI Compatible API |
| 8888         | 8888          | Jupyter Lab            |
| 2999         | 2999          | RunPod File Uploader   |

## Environment Variables

| Variable           | Description                                  | Default                                |
|--------------------|----------------------------------------------|----------------------------------------|
| VENV_PATH          | Set the path for the Python venv for the app | /workspace/venvs/text-generation-webui |
| DISABLE_AUTOLAUNCH | Disable Web UI from launching automatically  | (not set)                              |

## Logs

Text Generation Web UI creates a log file, and you can tail the log instead of
killing the service to view the logs.

| Application            | Log file                    |
|------------------------|-----------------------------|
| Text Generation Web UI | /workspace/logs/textgen.log |

For example:

```bash
tail -f /workspace/logs/textgen.log
```

## Community and Contributing

Pull requests and issues on [GitHub](https://github.com/ashleykleynhans/text-generation-docker)
are welcome. Bug fixes and new features are encouraged.

You can contact me and get help with deploying your container
to RunPod on the RunPod Discord Server below,
my username is **ashleyk**.

<a target="_blank" href="https://discord.gg/pJ3P2DbUUq">![Discord Banner 2](https://discordapp.com/api/guilds/912829806415085598/widget.png?style=banner2)</a>

## Appreciate my work?

<a href="https://www.buymeacoffee.com/ashleyk" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
