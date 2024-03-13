variable "USERNAME" {
    default = "ashleykza"
}

variable "APP" {
    default = "oobabooga"
}

variable "RELEASE" {
    default = "1.13.2"
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
        TORCH_VERSION = "2.2.0+cu${CU_VERSION}"
        XFORMERS_VERSION = "0.0.24"
        OOBABOOGA_COMMIT = "1934cb61ef879815644277c01c7295acbae542d8"
        RUNPODCTL_VERSION = "v1.14.2"
        VENV_PATH = "/workspace/venvs/text-generation-webuii"
    }
}
