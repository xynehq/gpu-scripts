# Setup script for sglang
set -e

VENV_DIR="venv"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null
then
    echo "python3 could not be found. Please install Python 3."
    exit 1
fi

# Create virtual environment if it doesn't exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment in $VENV_DIR..."
    python3 -m venv "$VENV_DIR"
    if [ $? -ne 0 ]; then
        echo "Failed to create virtual environment. Exiting."
        exit 1
    fi
else
    echo "Using existing Python virtual environment in $VENV_DIR."
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
if [ $? -ne 0 ]; then
    echo "Failed to activate virtual environment. Exiting."
    exit 1
fi

echo "Installing sglang and huggingface_hub CLI into the virtual environment..."
pip install "sglang[all]" "huggingface_hub[cli]"

echo "Updating package list and installing libnuma1 (system-wide)..."
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

echo "Deactivating virtual environment..."
deactivate

echo ""
echo "Setup complete."
echo "Models have been processed and downloaded (if selected)."
echo "To start the SGLang server, run: ./start-sglang.sh"
