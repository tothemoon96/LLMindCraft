FROM nvcr.io/nvidia/pytorch:23.04-py3
# ubuntu 20.04
# python 3.8
# cuda 12.1.0
# torch 2.1.0a0+fe05266f
# nccl 2.17.1
LABEL maintainer="tothemoon"
WORKDIR /workspace
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y
RUN apt-get install -y apt-utils
RUN apt-get install -y curl build-essential zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev wget g++-11 cmake ninja-build python3-dev libssl-dev git-lfs libaio-dev netcat moreutils python3 python3-pip
RUN apt-get install -y locales \
    && locale-gen zh_CN.UTF-8 \
    && locale-gen en_US.UTF-8 \
    && echo -e '\nexport LANG=zh_CN.UTF-8' >> /root/.bashrc
RUN apt-get install -y tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

RUN python3 -m pip install -U --no-cache-dir pip setuptools pudb
# delete packages depend on torch
RUN pip uninstall -y torch transformer-engine flash-attn apex torch-tensorrt torchtext torchvision

# build pytorch
RUN git clone --recursive https://github.com/pytorch/pytorch.git
RUN cd pytorch && \
    git checkout v2.1.2 && \
    git submodule sync && \
    git submodule update --init --recursive
ENV PYTORCH_BUILD_VERSION=2.1.2 PYTORCH_VERSION=2.1.2 PYTORCH_BUILD_NUMBER=0 TARGETARCH=amd64 PYVER=3.8
ENV TORCH_CUDA_ARCH_LIST="7.0;7.2;7.5;8.0;8.6;8.7;8.9;9.0"
RUN cd pytorch && \
    MAX_JOBS=208 \
    BUILD_TEST=0 \
    USE_CUPTI_SO=1 \
    USE_KINETO=1 \
    CMAKE_PREFIX_PATH="/usr/local" \
    NCCL_ROOT="/usr" \
    NCCL_INCLUDE_DIR="/usr/include/" \
    NCCL_LIB_DIR="/usr/lib/" \
    USE_SYSTEM_NCCL=1 \
    CFLAGS='-fno-gnu-unique' \
    DEFAULT_INTEL_MKL_DIR="/usr/local" \
    INTEL_MKL_DIR="/usr/local" \
    python3 setup.py install && \
    python3 setup.py clean

# build vllm
RUN git clone --recursive https://github.com/vllm-project/vllm.git && \
    cd vllm && \
    git checkout v0.4.0.post1 && \
    git submodule sync && \
    git submodule update --init --recursive
RUN cd vllm && \
    MAX_JOBS=208 \
    python3 -m pip install -e .

# # vim
# RUN wget -O /root/.vimrc 'https://api.onedrive.com/v1.0/shares/u!aHR0cHM6Ly8xZHJ2Lm1zL3UvcyFBc01LbTN0MEszbFlnWlZsc0JJM1hhTGR3bWNJNHc/root/content' \
#     && git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim \
#     && vim +PluginInstall +qall

# # pudb
# RUN mkdir -p /root/.config/pudb \
#     && wget -O /root/.config/pudb/pudb.cfg 'https://api.onedrive.com/v1.0/shares/u!aHR0cHM6Ly8xZHJ2Lm1zL3UvcyFBc01LbTN0MEszbFlnWlZrQjlYNDQtTEJHWnoxVVE/root/content'


# RUN python3 -m pip install -U --no-cache-dir transformers-stream-generator 
# ENTRYPOINT ["/usr/bin/python3", "-m", "vllm.entrypoints.openai.api_server"]
# CMD ["--tensor-parallel-size", "8"]