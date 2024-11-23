# Stage 1: Base
FROM nvidia/cuda:12.6.2-cudnn-devel-ubuntu22.04 as base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=on \
    SHELL=/bin/bash

# Install Ubuntu packages
RUN apt update && \
    apt -y upgrade && \
    apt install -y --no-install-recommends \
        software-properties-common \
        build-essential \
        python3.10-venv \
        python3-pip \
        python3-tk \
        python3-dev \
        nginx \
        bash \
        dos2unix \
        git \
        ncdu \
        net-tools \
        openssh-server \
        libglib2.0-0 \
        libsm6 \
        libgl1 \
        libxrender1 \
        libxext6 \
        ffmpeg \
        wget \
        curl \
        psmisc \
        rsync \
        vim \
        zip \
        unzip \
        htop \
        screen \
        tmux \
        pkg-config \
        libcairo2-dev \
        libgoogle-perftools4 \
        libtcmalloc-minimal4 \
        apt-transport-https \
        ca-certificates && \
    update-ca-certificates && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Set Python symlink
RUN ln -s /usr/bin/python3.10 /usr/bin/python

# Stage 2: Install FaceFusion and Python modules
FROM base as setup

# Install micromamba (conda replacement)
RUN mkdir -p /opt/micromamba && \
    cd /opt/micromamba && \
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvJ bin/micromamba && \
    ln -s /opt/micromamba/bin/micromamba /usr/local/bin/micromamba

# Initialize micromamba
RUN micromamba shell init -s bash && \
    micromamba config append channels conda-forge

# Create the facefusion environment
RUN micromamba create -y -n facefusion python=3.10

# Set micromamba as the default shell for subsequent commands
SHELL ["micromamba", "run", "-n", "facefusion", "/bin/bash", "-c"]

# Clone the FaceFusion repository and set version
WORKDIR /
ARG FACEFUSION_VERSION
RUN git clone https://github.com/archivalboat50/facefusion_runpod_modificationv3.git && \
    cd /facefusion_runpod_modificationv3 && \
    git checkout ${FACEFUSION_VERSION}

# Install Torch
ARG INDEX_URL
ARG TORCH_VERSION
ENV TORCH_INDEX_URL=${INDEX_URL}
ENV TORCH_COMMAND="pip3 install torch==${TORCH_VERSION} torchvision --index-url ${TORCH_INDEX_URL}"
RUN ${TORCH_COMMAND}

# Install the dependencies for FaceFusion
ARG FACEFUSION_CUDA_VERSION
WORKDIR /facefusion_runpod_modificationv3
RUN python3 install.py --onnxruntime cuda-${FACEFUSION_CUDA_VERSION}

# Install Jupyter, gdown, and OhMyRunPod
RUN pip3 install -U --no-cache-dir jupyterlab \
    jupyterlab_widgets \
    ipykernel \
    ipywidgets \
    gdown \
    OhMyRunPod

# Install RunPod File Uploader
RUN curl -sSL https://github.com/kodxana/RunPod-FilleUploader/raw/main/scripts/installer.sh -o installer.sh && \
    chmod +x installer.sh && \
    ./installer.sh

# Install rclone
RUN curl https://rclone.org/install.sh | bash

# Install runpodctl
ARG RUNPODCTL_VERSION
RUN wget "https://github.com/runpod/runpodctl/releases/download/${RUNPODCTL_VERSION}/runpodctl-linux-amd64" -O runpodctl && \
    chmod a+x runpodctl && \
    mv runpodctl /usr/local/bin

# Install croc
RUN curl https://getcroc.schollz.com | bash

# Install speedtest CLI
RUN curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | bash && \
    apt install -y speedtest

# Remove existing SSH host keys
RUN rm -f /etc/ssh/ssh_host_*

# NGINX Proxy
COPY nginx/nginx.conf /etc/nginx/nginx.conf
COPY nginx/502.html /usr/share/nginx/html/502.html

# Set template version
ARG RELEASE
ENV TEMPLATE_VERSION=${RELEASE}

# Copy the scripts
WORKDIR /
COPY --chmod=755 scripts/* ./

# Start the container
SHELL ["/bin/bash", "--login", "-c"]
CMD [ "/start.sh" ]
