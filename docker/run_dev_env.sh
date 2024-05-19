docker run --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 \
    --privileged \
    --network=host \
    -v /home/hanweiguang/Projects:/root/Projects \
    -w /root/Projects \
    -d --rm \
    --name llm_cu124 \
    llm_cu124 \
    --cmd 'sleep infinity'