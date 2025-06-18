# Setup script for sglang
set -e

VENV_DIR="venv"

# Check if Python 3 is available
if ! command -v python3 &> /dev/null
then
    echo "python3 could not be found. Please install Python 3."
    exit 1
fi

# Check for NVIDIA drivers and CUDA Toolkit
echo "--- NVIDIA Driver and CUDA Toolkit Check ---"
if ! command -v nvidia-smi &> /dev/null; then
    echo "Error: nvidia-smi command not found. NVIDIA drivers may not be installed or not in PATH."
    echo "Please install NVIDIA drivers for your GPU and ensure nvidia-smi is accessible."
    exit 1
else
    echo "NVIDIA drivers detected via nvidia-smi."
    NVIDIA_DRIVER_VERSION=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader | head -n 1)
    echo "Detected NVIDIA Driver Version: $NVIDIA_DRIVER_VERSION"
fi

TARGET_CUDA_MAJOR=12
TARGET_CUDA_MINOR=1
CUDA_VERSION_OK=false

if command -v nvcc &> /dev/null; then
    echo "nvcc (CUDA Toolkit Compiler Driver) found."
    NVCC_VERSION_OUTPUT=$(nvcc --version)
    # Example output: Cuda compilation tools, release 12.1, V12.1.66
    # Looking for "release X.Y"
    if [[ "$NVCC_VERSION_OUTPUT" =~ release\ ([0-9]+)\.([0-9]+) ]]; then
        INSTALLED_CUDA_MAJOR=${BASH_REMATCH[1]}
        INSTALLED_CUDA_MINOR=${BASH_REMATCH[2]}
        echo "Detected CUDA Toolkit Version: $INSTALLED_CUDA_MAJOR.$INSTALLED_CUDA_MINOR"
        if [ "$INSTALLED_CUDA_MAJOR" -gt "$TARGET_CUDA_MAJOR" ] || \
           ( [ "$INSTALLED_CUDA_MAJOR" -eq "$TARGET_CUDA_MAJOR" ] && [ "$INSTALLED_CUDA_MINOR" -ge "$TARGET_CUDA_MINOR" ] ); then
            echo "Installed CUDA Toolkit version ($INSTALLED_CUDA_MAJOR.$INSTALLED_CUDA_MINOR) meets the minimum requirement ($TARGET_CUDA_MAJOR.$TARGET_CUDA_MINOR or newer)."
            CUDA_VERSION_OK=true
        else
            echo "Installed CUDA Toolkit version ($INSTALLED_CUDA_MAJOR.$INSTALLED_CUDA_MINOR) is older than the recommended version ($TARGET_CUDA_MAJOR.$TARGET_CUDA_MINOR or newer)."
        fi
    else
        echo "Could not parse CUDA Toolkit version from nvcc output. Output was:"
        echo "$NVCC_VERSION_OUTPUT"
    fi
else
    echo "nvcc (CUDA Toolkit Compiler Driver) not found in PATH."
fi

if [ "$CUDA_VERSION_OK" = false ]; then
    echo ""
    echo "A CUDA Toolkit version $TARGET_CUDA_MAJOR.$TARGET_CUDA_MINOR or newer is recommended for SGLang."
    echo "You mentioned previously that cuda-toolkit-12-8 worked on your system."
    echo "The script can attempt to install cuda-toolkit-$TARGET_CUDA_MAJOR-$TARGET_CUDA_MINOR (e.g., cuda-toolkit-12-1)."
    
    # Check if apt is available before offering to install
    if ! command -v apt &> /dev/null; then
        echo "Error: 'apt' command not found. Cannot attempt automatic installation of CUDA toolkit."
        echo "Please install CUDA Toolkit $TARGET_CUDA_MAJOR.$TARGET_CUDA_MINOR or newer manually."
        exit 1
    fi

    read -r -p "Would you like this script to attempt to install cuda-toolkit-$TARGET_CUDA_MAJOR-$TARGET_CUDA_MINOR now? (y/N): " choice
    if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
        echo "Attempting to install cuda-toolkit-$TARGET_CUDA_MAJOR-$TARGET_CUDA_MINOR..."
        if sudo apt-get update && sudo apt-get install -y "cuda-toolkit-$TARGET_CUDA_MAJOR-$TARGET_CUDA_MINOR"; then
            echo "CUDA Toolkit $TARGET_CUDA_MAJOR.$TARGET_CUDA_MINOR installation attempted."
            echo "Please verify the installation and ensure your PATH/LD_LIBRARY_PATH are correctly set."
            echo "You might need to reboot or re-login for changes to take effect."
            echo "Re-checking for nvcc..."
            if command -v nvcc &> /dev/null; then
                 NVCC_VERSION_OUTPUT_AFTER_INSTALL=$(nvcc --version)
                 echo "nvcc found after installation attempt. Version info:"
                 echo "$NVCC_VERSION_OUTPUT_AFTER_INSTALL"
            else
                 echo "nvcc still not found after installation attempt. Please check manually."
                 exit 1
            fi
        else
            echo "Failed to install cuda-toolkit-$TARGET_CUDA_MAJOR-$TARGET_CUDA_MINOR. Please install it manually."
            exit 1
        fi
    else
        echo "Skipping automatic CUDA Toolkit installation."
        echo "Please ensure CUDA Toolkit $TARGET_CUDA_MAJOR.$TARGET_CUDA_MINOR or newer is installed and configured before proceeding."
        exit 1
    fi
fi
echo "--- End NVIDIA Driver and CUDA Toolkit Check ---"
echo ""

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

echo "Installing sglang, huggingface_hub CLI, and nvitop into the virtual environment..."
pip install "sglang[all]" "huggingface_hub[cli]" nvitop

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
