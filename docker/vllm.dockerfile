FROM nvcr.io/nvidia/pytorch:23.07-py3
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

RUN python3 -m pip install -U --no-cache-dir pip setuptools
RUN mkdir -p /workspace && cd /workspace && \
    git clone https://github.com/vllm-project/vllm.git && cd vllm && \
    git checkout v0.4.0 && \
    TORCH_CUDA_ARCH_LIST="7.0;7.5;8.0;8.6;8.9;9.0" \
    MAX_JOBS=208 \
    python3 -m pip install -e .

RUN python3 -m pip install -U --no-cache-dir transformers-stream-generator 
ENTRYPOINT ["/usr/bin/python3", "-m", "vllm.entrypoints.openai.api_server"]
CMD ["--tensor-parallel-size", "8"]