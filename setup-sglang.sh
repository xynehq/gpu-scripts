# Setup script for sglang
set -e

echo "Installing sglang and huggingface_hub CLI..."
pip3 install "sglang[all]" "huggingface_hub[cli]"

echo "Updating package list and installing libnuma1..."
sudo apt-get update && sudo apt-get install -y libnuma1

MODEL_FILE="model.txt"

if [ ! -f "$MODEL_FILE" ]; then
    echo "Error: $MODEL_FILE not found!"
    exit 1
fi

echo "Reading models from $MODEL_FILE..."
mapfile -t MODELS_TO_PROCESS < "$MODEL_FILE"

if [ ${#MODELS_TO_PROCESS[@]} -eq 0 ]; then
    echo "No models found in $MODEL_FILE. Exiting."
    exit 1
fi

echo "Found models:"
for model_id in "${MODELS_TO_PROCESS[@]}"; do
    echo "- $model_id"
done
echo ""

echo "--- Model Download ---"
for model_id in "${MODELS_TO_PROCESS[@]}"; do
    read -r -p "Download model '$model_id'? (y/n): " choice
    case "$choice" in
      y|Y )
        echo "Downloading $model_id..."
        huggingface-cli download "$model_id"
        ;;
      * )
        echo "Skipping download for $model_id."
        ;;
    esac
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
DETECT_GPU_SCRIPT="detect_gpus.py" 
if [ ! -f "$DETECT_GPU_SCRIPT" ]; then
    echo "Error: $DETECT_GPU_SCRIPT not found in the current directory. Cannot detect GPUs."
    exit 1
fi
num_gpus=$(python "$DETECT_GPU_SCRIPT")


echo "Launching sglang server with model $SELECTED_MODEL_FOR_SERVER and tensor parallel size $num_gpus..."
python -m sglang.launch_server --model-path "$SELECTED_MODEL_FOR_SERVER" --tensor-parallel-size "$num_gpus"
