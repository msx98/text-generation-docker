variable "USERNAME" {
    default = "ashleykza"
}

variable "APP" {
    default = "oobabooga"
}

variable "RELEASE" {
    default = "1.15.0"
}

variable "CU_VERSION" {
    default = "121"
}

target "default" {
    dockerfile = "Dockerfile"
    tags = ["${USERNAME}/${APP}:${RELEASE}"]
    args = {
        RELEASE = "${RELEASE}"
        INDEX_URL = "https://download.pytorch.org/whl/cu${CU_VERSION}"
        TORCH_VERSION = "2.2.1+cu${CU_VERSION}"
        OOBABOOGA_COMMIT = "65099dc192b3b75327e4e4fe10a5cac0d46a6b10"
        RUNPODCTL_VERSION = "v1.14.2"
        VENV_PATH = "/workspace/venvs/text-generation-webui"
    }
}
