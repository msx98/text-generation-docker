# Docker image for the Text Generation Web UI: A Gradio web UI for Large Language Models. Supports transformers, GPTQ, llama.cpp (GGUF), Llama models

> [!NOTE]
> The legacy APIs no longer work with the latest version of the
> Text Generation Web UI, and have been deprecated since
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
* Torch 2.1.2
* xformers 0.0.23.post1
* [runpodctl](https://github.com/runpod/runpodctl)
* [croc](https://github.com/schollz/croc)
* [rclone](https://rclone.org/)

## Available on RunPod

This image is designed to work on [RunPod](https://runpod.io?ref=2xxro4sy).
You can use my custom [RunPod template](
https://runpod.io/gsc?template=el5m58e1to&ref=2xxro4sy)
to launch it on RunPod.

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
  -e JUPYTER_PASSWORD=Jup1t3R! \
  ashleykza/oobabooga:latest
```

You can obviously substitute the image name and tag with your own.

## Community and Contributing

Pull requests and issues on [GitHub](https://github.com/ashleykleynhans/text-generation-docker)
are welcome. Bug fixes and new features are encouraged.

You can contact me and get help with deploying your container
to RunPod on the RunPod Discord Server below,
my username is **ashleyk**.

<a target="_blank" href="https://discord.gg/pJ3P2DbUUq">![Discord Banner 2](https://discordapp.com/api/guilds/912829806415085598/widget.png?style=banner2)</a>

## Appreciate my work?

<a href="https://www.buymeacoffee.com/ashleyk" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
