FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04 AS base_cuda

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ="Europe/Berlin"
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install basic dependencies and configure locales
# Install some dependencies for Hailo Dataflow Compiler
# See https://hailo.ai/developer-zone/documentation/v3-28-0/?sp_referrer=install/install.html
# Also: https://pygraphviz.github.io/documentation/stable/install.html
RUN apt-get update && apt-get install --no-install-recommends -y \
    locales \
    python3 \
    python3-pip \
    curl \
    libgl1 \
    libglib2.0-0 \
    git \
    build-essential \
    python3.10-dev \
    python3.10-distutils \
    python3-tk \
    libfuse2 \
    graphviz \
    graphviz-dev \
    libgraphviz-dev \
    sudo && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure locales && \
    update-locale && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install pygraphviz
RUN pip install --no-cache-dir pygraphviz

# Setup non-root user
ARG USERNAME=hailo
ARG USER_UID=1000
ARG USER_GID=$USER_UID

RUN groupadd --gid $USER_GID $USERNAME && \
    useradd --uid $USER_UID --gid $USER_GID -m $USERNAME && \
    echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME && \
    chmod 0440 /etc/sudoers.d/$USERNAME

# Switch to non-root user
USER $USERNAME

# Copy and install Hailo Dataflow Compiler
# See https://hailo.ai/developer-zone/documentation/v3-28-0/?sp_referrer=install/install.html
# Set PATH so that some Hailo binaries are available
ENV PATH="/home/hailo/.local/bin:${PATH}"
COPY ./hailo_dataflow_compiler-3.28.0-py3-none-linux_x86_64.whl /home/$USERNAME/hailo_dataflow_compiler-3.28.0-py3-none-linux_x86_64.whl
RUN pip install /home/$USERNAME/hailo_dataflow_compiler-3.28.0-py3-none-linux_x86_64.whl && rm /home/$USERNAME/hailo_dataflow_compiler-3.28.0-py3-none-linux_x86_64.whl

# Install Hailo Model Zoo
# https://github.com/hailo-ai/hailo_model_zoo?tab=readme-ov-file#quick-start-guide
RUN git clone https://github.com/hailo-ai/hailo_model_zoo.git /home/$USERNAME/hailo_model_zoo && \
    pip install -e /home/$USERNAME/hailo_model_zoo && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["hailomz", "compile", "--ckpt", "best.onnx", "--hw-arch", "hailo8l", "--calib-path", "calibration_imgs/", "--yaml", "yolov8s_custom.yaml", "--model-script", "yolov8s_custom.alls", "--classes", "1"]