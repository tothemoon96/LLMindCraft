docker_name=vllm_build_debug

docker run --gpus all --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 \
      --privileged \
      --network=host \
      -it --rm \
      -e CUDA_VISIBLE_DEVICES=$CUDA_VISIBLE_DEVICES \
      -v /nfs:/nfs \
      -v /nfs3:/nfs3 \
      -v /mnt:/mnt \
      -w /workspace \
      --name $docker_name \
      --entrypoint /bin/bash \
      vllm