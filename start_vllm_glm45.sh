#!/bin/bash

# Script to start vLLM server for GLM-4.5V-FP8 model
# This script includes workarounds for common issues with FP8 models

MODEL_ID="${1:-zai-org/GLM-4.5V-FP8}"
PORT="${2:-8000}"

echo "Starting vLLM server for model: $MODEL_ID on port $PORT"
echo "=================================================="
echo ""

# Solution 1: Use V0 engine (recommended for FP8 models with issues)
echo "Trying with V0 engine (--disable-v1)..."
vllm serve "$MODEL_ID" \
    --tensor-parallel-size 2 \
    --tool-call-parser glm45 \
    --reasoning-parser glm45 \
    --enable-auto-tool-choice \
    --allowed-local-media-path / \
    --media-io-kwargs '{"video": {"num_frames": -1}}' \
    --disable-v1 \
    --port "$PORT"

# If above fails, the script will exit
# Alternative solutions are provided below as comments:

# Solution 2: Disable torch compile (if V0 engine alone doesn't work)
# vllm serve "$MODEL_ID" \
#     --tensor-parallel-size 2 \
#     --tool-call-parser glm45 \
#     --reasoning-parser glm45 \
#     --enable-auto-tool-choice \
#     --allowed-local-media-path / \
#     --media-io-kwargs '{"video": {"num_frames": -1}}' \
#     --disable-v1 \
#     --compilation-config '{"level": 0}' \
#     --port "$PORT"

# Solution 3: Use BF16 model instead if FP8 continues to fail
# vllm serve "THUDM/glm-4v-9b" \
#     --tensor-parallel-size 2 \
#     --tool-call-parser glm45 \
#     --reasoning-parser glm45 \
#     --enable-auto-tool-choice \
#     --allowed-local-media-path / \
#     --media-io-kwargs '{"video": {"num_frames": -1}}' \
#     --port "$PORT"
