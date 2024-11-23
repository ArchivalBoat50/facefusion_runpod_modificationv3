variable "USERNAME" {
    default = "archivalboat50"
}

variable "APP" {
    default = "facefusion"
}

variable "RELEASE" {
    default = "3.0.1"
}

variable "CU_VERSION" {
    default = "126"
}

target "default" {
    dockerfile = "Dockerfile"
    tags = ["${USERNAME}/${APP}:${RELEASE}"]
    args = {
        RELEASE = "${RELEASE}"
        INDEX_URL = "https://download.pytorch.org/whl/cu${CU_VERSION}"
        TORCH_VERSION = "2.0.1+cu${CU_VERSION}"
        FACEFUSION_VERSION = "${RELEASE}"
        FACEFUSION_CUDA_VERSION = "12.6"
        RUNPODCTL_VERSION = "v1.14.3"
    }
}
