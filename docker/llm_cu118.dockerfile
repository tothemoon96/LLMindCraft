FROM nvcr.io/nvidia/pytorch:22.12-py3
# ubuntu 20.04
# python 3.8
# cuda 11.8.0
# torch 1.14.0a0+410ce96
# nccl 2.15.5
LABEL maintainer="tothemoon"
WORKDIR /workspace
ENV DEBIAN_FRONTEND=noninteractive

RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
  && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
  && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
  && apt-get update -y \
  && apt-get install gh -y
RUN apt-get update -y && apt-get install -y g++-11 cmake ninja-build python3-dev libssl-dev git-lfs
  
RUN apt-get install -y libaio-dev
RUN apt-get install -y netcat
RUN apt-get install -y htop
RUN apt-get install -y screen
RUN apt-get install -y tmux
RUN apt-get install -y locales \
    && locale-gen en_US.UTF-8 \
    && locale-gen zh_CN.UTF-8 \
    && echo -e 'export LANG=zh_CN.UTF-8' >> /root/.bashrc
RUN apt-get install -y tzdata \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN apt-get install -y net-tools
RUN apt-get install -y openssh-server \
    && sed -i "s/#PermitRootLogin prohibit-password/PermitRootLogin yes/" /etc/ssh/sshd_config \
    && sed -i "s/#PubkeyAuthentication yes/PubkeyAuthentication yes/" /etc/ssh/sshd_config \
    && sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config \
    && echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
    && mkdir -p /run/sshd
RUN apt-get install -y pdsh \
    && chown root:root /usr/lib/x86_64-linux-gnu/pdsh \
    && chmod 755 /usr/lib/x86_64-linux-gnu/pdsh \
    && chown root:root /usr/lib \
    && chmod 755 /usr/lib
RUN apt-get install -y bash-completion
RUN apt-get install -y socat
RUN apt-get install -y locate
RUN apt-get install -y cron
RUN apt-get install -y zip
RUN apt-get install -y fuse
RUN apt-get install -y moreutils
RUN apt-get install -y bc

# IB网卡驱动：https://network.nvidia.com/products/infiniband-drivers/linux/mlnx_ofed/
# ENV MOFED_VER=23.10-1.1.9.0
# ENV PLATFORM=x86_64
# RUN OS_VER="ubuntu$(cat /etc/os-release | grep VERSION_ID | cut -d '"' -f 2)" \
#     && wget http://content.mellanox.com/ofed/MLNX_OFED-${MOFED_VER}/MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}.tgz \
#     && tar -xvf MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}.tgz \
#     && rm -rf MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}.tgz
# RUN OS_VER="ubuntu$(cat /etc/os-release | grep VERSION_ID | cut -d '"' -f 2)" \
#     && MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}/mlnxofedinstall --user-space-only --without-fw-update -q \
#     && rm -rf MLNX_OFED_LINUX-${MOFED_VER}-${OS_VER}-${PLATFORM}

RUN pip install -U --no-cache-dir pip
RUN pip install -U --no-cache-dir setuptools

RUN pip uninstall -y transformer-engine flash-attn
# 依赖pytorch，需要重新编译
ENV FLASH_ATTENTION_VERSION=2.4.2
RUN git clone --recursive https://github.com/Dao-AILab/flash-attention.git && \
    cd flash-attention && \
    git checkout v${FLASH_ATTENTION_VERSION} && \
    git submodule sync && \
    git submodule update --init --recursive
RUN cd flash-attention && \
    MAX_JOBS=208 FLASH_ATTENTION_FORCE_BUILD=TRUE FLASH_ATTENTION_FORCE_CXX11_ABI=FALSE python setup.py bdist_wheel && \
    cd dist && \
    pip install flash_attn-${FLASH_ATTENTION_VERSION}-cp38-cp38-linux_x86_64.whl && \
    cd .. && \
    python3 setup.py clean
RUN cd flash-attention/csrc/layer_norm \
    && MAX_JOBS=208 pip install .
RUN cd flash-attention/csrc/rotary \
    && MAX_JOBS=208 pip install .

RUN MAX_JOBS=208 pip install -U --no-cache-dir git+https://github.com/NVIDIA/TransformerEngine.git@v1.4
RUN pip install --no-cache-dir git+https://github.com/fanshiqing/grouped_gemm@main

# # xformers依赖pytorch和flash-attention，可能影响pytorch版本，进而影响nccl版本，重装nccl
# RUN pip install -U --no-cache-dir --no-deps xformers==0.0.22.post7 --index-url https://download.pytorch.org/whl/cu121
RUN pip install -U --no-cache-dir bitsandbytes

RUN pip install -U --no-cache-dir gradio mdtex2html
RUN pip install -U --no-cache-dir pudb
# # 和deepspeed冲突
# RUN pip install -U --no-cache-dir install git+https://github.com/wookayin/gpustat.git@master \
#     && pip uninstall -y nvidia-ml-py3 pynvml \
#     && pip install --force-reinstall --ignore-installed 'nvidia-ml-py'
RUN pip install -U --no-cache-dir ipykernel
RUN pip install -U --no-cache-dir ipywidgets
RUN pip install -U --no-cache-dir httpx[socks]
RUN pip install -U --no-cache-dir wandb
RUN pip install -U --no-cache-dir openpyxl xlrd
RUN pip install -U --no-cache-dir jsonlines
RUN pip install -U --no-cache-dir fire openai
RUN pip install -U --no-cache-dir rich
RUN pip install -U --no-cache-dir pylcs
# magatron
ENV CUDA=cu11
ENV PYTHON=cp38
RUN pip install --no-cache-dir tensorstore==0.1.45
RUN pip install --no-cache-dir zarr
RUN wget https://github.com/CVCUDA/CV-CUDA/releases/download/v0.6.0-beta/cvcuda_${CUDA}-0.6.0b0-${PYTHON}-${PYTHON}-linux_x86_64.whl \
    && pip install cvcuda_${CUDA}-0.6.0b0-${PYTHON}-${PYTHON}-linux_x86_64.whl \
    && rm -rf cvcuda_${CUDA}-0.6.0b0-${PYTHON}-${PYTHON}-linux_x86_64.whl

# huggingface全家桶
RUN pip uninstall -y trl accelerate transformers peft deepspeed datasets
RUN pip install --no-cache-dir transformers[deepspeed] \
    && pip install --no-cache-dir trl peft datasets
RUN pip install -U --no-cache-dir tiktoken transformers-stream-generator openai lm_dataformat ftfy nltk sentencepiece

# vim
RUN wget -O /root/.vimrc 'https://api.onedrive.com/v1.0/shares/u!aHR0cHM6Ly8xZHJ2Lm1zL3UvcyFBc01LbTN0MEszbFlnWlZsc0JJM1hhTGR3bWNJNHc/root/content' \
    && git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim \
    && vim +PluginInstall +qall

# pudb
RUN mkdir -p /root/.config/pudb \
    && wget -O /root/.config/pudb/pudb.cfg 'https://api.onedrive.com/v1.0/shares/u!aHR0cHM6Ly8xZHJ2Lm1zL3UvcyFBc01LbTN0MEszbFlnWlZrQjlYNDQtTEJHWnoxVVE/root/content'

# htop
RUN mkdir -p /root/.config/htop \
    && wget -O /root/.config/htop/htoprc 'https://api.onedrive.com/v1.0/shares/u!aHR0cHM6Ly8xZHJ2Lm1zL3UvcyFBc01LbTN0MEszbFlnWllUeHZqZUMyb2N0MzVKZlE/root/content'

# screenrc
RUN echo 'termcapinfo xterm* ti@:te@' > /root/.screenrc

RUN mkdir -p /scripts && echo -e '#!/bin/bash\n\
SSHD_PORT=22001\n\
CMD_TO_RUN=""\n\
while (( "$#" )); do\n\
  case "$1" in\n\
    --sshd_port)\n\
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then\n\
        SSHD_PORT=$2\n\
        shift 2\n\
      else\n\
        echo "Error: Argument for $1 is missing" >&2\n\
        exit 1\n\
      fi\n\
      ;;\n\
    --cmd)\n\
      if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then\n\
        CMD_TO_RUN=$2\n\
        shift 2\n\
      else\n\
        echo "Error: Argument for $1 is missing" >&2\n\
        exit 1\n\
      fi\n\
      ;;\n\
    -*|--*=) \n\
      echo "Error: Unsupported flag $1" >&2\n\
      exit 1\n\
      ;;\n\
    *) \n\
      shift\n\
      ;;\n\
  esac\n\
done\n\
sed -i "s/#Port 22/Port $SSHD_PORT/" /etc/ssh/sshd_config\n\
/usr/sbin/sshd\n\
if [ -n "$CMD_TO_RUN" ]; then\n\
  bash -c "$CMD_TO_RUN"\n\
else\n\
  /bin/bash\n\
fi' > /scripts/startup.sh && chmod +x /scripts/startup.sh

ENTRYPOINT ["/bin/bash", "/scripts/startup.sh"]
