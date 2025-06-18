#!/bin/bash
# Script to start the SGLang server
set -e

VENV_DIR="venv"
MODEL_FILE="model.txt"
DETECT_GPU_SCRIPT="detect_gpus.py"
CHECK_MODEL_CACHED_SCRIPT="check_model_cached.py"

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

echo "Reading potential models from $MODEL_FILE..."
mapfile -t POTENTIAL_MODELS < "$MODEL_FILE"

if [ ${#POTENTIAL_MODELS[@]} -eq 0 ]; then
    echo "No models found in $MODEL_FILE. Exiting."
    exit 1
fi

if [ ! -f "$CHECK_MODEL_CACHED_SCRIPT" ]; then
    echo "Error: $CHECK_MODEL_CACHED_SCRIPT not found. Cannot verify cached models."
    exit 1
fi
if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
    echo "Error: Python interpreter not found. Cannot run $CHECK_MODEL_CACHED_SCRIPT."
    exit 1
fi
PYTHON_CMD=$(command -v python3 || command -v python)


echo "Checking which models from $MODEL_FILE are locally cached..."
AVAILABLE_MODELS=()
for model_id in "${POTENTIAL_MODELS[@]}"; do
    # Remove potential trailing whitespace/CR from model_id read by mapfile
    model_id_clean=$(echo "$model_id" | tr -d '[:space:]')
    if [ -z "$model_id_clean" ]; then
        continue
    fi
    
    # Use the Python from the activated venv to run the check script
    if "$PYTHON_CMD" "$CHECK_MODEL_CACHED_SCRIPT" "$model_id_clean"; then
        echo "- $model_id_clean (Cached)"
        AVAILABLE_MODELS+=("$model_id_clean")
    else
        echo "- $model_id_clean (Not cached or config.json missing)"
    fi
done
echo ""

if [ ${#AVAILABLE_MODELS[@]} -eq 0 ]; then
    echo "No locally cached models found from the list in $MODEL_FILE."
    echo "Please run ./setup-sglang.sh to download models or ensure they are correctly cached."
    exit 1
fi

echo "--- Select Model for SGLang Server (from cached models) ---"
echo "Please select a model to launch the SGLang server with:"
select SELECTED_MODEL_FOR_SERVER in "${AVAILABLE_MODELS[@]}"; do
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
