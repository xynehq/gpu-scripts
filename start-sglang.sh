#!/bin/bash
# Script to start the SGLang server
set -e

VENV_DIR="venv"
MODEL_FILE="model.txt"
DETECT_GPU_SCRIPT="detect_gpus.py"

# Check if virtual environment exists
if [ ! -d "$VENV_DIR" ]; then
    echo "Error: Python virtual environment not found in $VENV_DIR."
    echo "Please run the setup script (setup-sglang.sh) first."
    exit 1
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
if [ $? -ne 0 ]; then
    echo "Failed to activate virtual environment. Exiting."
    exit 1
fi

# Check if model file exists
if [ ! -f "$MODEL_FILE" ]; then
    echo "Error: $MODEL_FILE not found!"
    echo "Please ensure $MODEL_FILE exists and contains model IDs."
    exit 1
fi

echo "Reading models from $MODEL_FILE..."
mapfile -t MODELS_TO_PROCESS < "$MODEL_FILE"

if [ ${#MODELS_TO_PROCESS[@]} -eq 0 ]; then
    echo "No models found in $MODEL_FILE. Exiting."
    exit 1
fi

echo "Available models:"
for model_id in "${MODELS_TO_PROCESS[@]}"; do
    echo "- $model_id"
done
echo ""

echo "--- Select Model for SGLang Server ---"
echo "Please select a model to launch the SGLang server with:"
select SELECTED_MODEL_FOR_SERVER in "${MODELS_TO_PROCESS[@]}"; do
    if [[ -n "$SELECTED_MODEL_FOR_SERVER" ]]; then
        echo "You selected: $SELECTED_MODEL_FOR_SERVER"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

if [ -z "$SELECTED_MODEL_FOR_SERVER" ]; then
    echo "No model selected for server launch. Exiting."
    exit 1
fi
echo ""

echo "Detecting number of GPUs available..."
if [ ! -f "$DETECT_GPU_SCRIPT" ]; then
    echo "Error: $DETECT_GPU_SCRIPT not found in the current directory. Cannot detect GPUs."
    exit 1
fi
num_gpus=$(python "$DETECT_GPU_SCRIPT")
if ! [[ "$num_gpus" =~ ^[0-9]+$ ]] || [ "$num_gpus" -lt 1 ]; then
    echo "Error: Failed to detect a valid number of GPUs. Detected: '$num_gpus'."
    echo "Please ensure $DETECT_GPU_SCRIPT is working correctly and GPUs are available."
    exit 1
fi

echo "Launching sglang server with model $SELECTED_MODEL_FOR_SERVER, tensor parallel size $num_gpus, host 0.0.0.0, and port 30000..."
python -m sglang.launch_server --model-path "$SELECTED_MODEL_FOR_SERVER" --tensor-parallel-size "$num_gpus" --host "0.0.0.0" --port 30000

echo "SGLang server process started."
echo "To stop the server, press Ctrl+C in this terminal or kill the process."

# Deactivate virtual environment (optional, as script will exit)
# deactivate
