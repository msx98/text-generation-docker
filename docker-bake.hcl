variable "USERNAME" {
    default = "ashleykza"
}

variable "APP" {
    default = "oobabooga"
}

variable "RELEASE" {
    default = "1.13.4"
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
        OOBABOOGA_COMMIT = "1a7c027386f43b84f3ca3b0ff04ca48d861c2d7a"
        RUNPODCTL_VERSION = "v1.14.2"
        VENV_PATH = "/workspace/venvs/text-generation-webui"
    }
}
