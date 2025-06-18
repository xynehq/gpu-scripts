# SGLang Server Management and Testing Utilities

## Overview

This suite of scripts provides utilities for setting up an SGLang (Efficient Language Model Serving) environment, managing language models, launching an SGLang server, testing its functionality, and benchmarking its performance. These scripts are designed to streamline the process of working with various Hugging Face language models via SGLang.

## Prerequisites

Before using these scripts, ensure your system meets the following requirements:

*   **Operating System:** Linux-based (due to `apt-get` for package installation).
*   **Python:** Python 3 and `pip3` installed.
*   **Permissions:** `sudo` privileges are required for installing system packages (e.g., `libnuma1`).
*   **Hardware:** 
    *   NVIDIA GPUs and their corresponding drivers are necessary for SGLang to run with GPU acceleration.
    *   A compatible CUDA Toolkit (version 12.1 or newer is recommended) must be installed. The `setup-sglang.sh` script attempts to verify this and can assist with installation on Debian/Ubuntu-based systems.
*   **Internet:** An active internet connection is needed for downloading Python packages and Hugging Face models.
*   **`jq` (Optional):** For pretty-printing JSON responses in `test_sglang_model.sh`. Install via `sudo apt-get install jq`.

## File Descriptions

*   **`model.txt`**:
    *   A plain text file where you list Hugging Face model identifiers (e.g., `Qwen/Qwen3-30B-A3B`), with one model per line. This file is crucial as it's used by other scripts to determine which models to download, launch, or test.

*   **`setup-sglang.sh`**:
    *   This script automates the initial environment setup, including CUDA checks, and model download process. It:
        *   Checks for Python 3.
        *   Verifies NVIDIA driver installation (via `nvidia-smi`).
        *   Checks for a compatible CUDA Toolkit (target version 12.1 or newer via `nvcc`). If not found or insufficient, it may offer to install `cuda-toolkit-12-1` with user permission.
        *   Creates or verifies a Python virtual environment (`venv`).
        *   Installs SGLang, `huggingface_hub[cli]` into the virtual environment.
        *   Installs system dependencies like `libnuma1` (if `apt-get` is available).
        *   Reads model identifiers from `model.txt`.
        *   Prompts the user to confirm the download for each model listed using `huggingface-cli` from the activated virtual environment.
        *   Guides the user to run `start-sglang.sh` to launch the server.

*   **`start-sglang.sh`**:
    *   This script launches the SGLang server. It:
        *   Activates the Python virtual environment.
        *   Reads model identifiers from `model.txt` and uses `check_model_cached.py` to filter for locally cached models.
        *   Prompts the user to select one of these cached models.
        *   Uses `detect_gpus.py` to determine the number of available GPUs.
        *   Launches the SGLang server with the selected model, detected GPU count, and configured host/port (defaults to `0.0.0.0:30000`).

*   **`test_sglang_model.sh`**:
    *   Allows interactive testing of a running SGLang server.
    *   If no model ID is provided as an argument, it reads models from `model.txt` and uses `check_model_cached.py` to filter for locally cached models, then presents these for selection.
    *   Sends a predefined list of diverse questions to the selected model.
    *   Supports both sequential and parallel API calls (user-selectable).

*   **`benchmark.sh`**:
    *   Benchmarks the performance (e.g., throughput, latency) of a selected model running on an SGLang server.
    *   Reads model identifiers from `model.txt` for user selection. (Note: This script does not currently filter by cached models, it assumes the selected model is available).
    *   **Note:** This script manages its own SGLang server instance for the duration of the benchmark, starting it with the selected model and stopping it afterward.
    *   Logs results to `sglang_benchmark_results.log` and errors to `sglang_benchmark_errors.log`.

*   **`check_model_cached.py`**:
    *   A Python utility script that checks if a given Hugging Face model ID is present in the local cache.
    *   It uses the `huggingface_hub` library to look for `config.json` of the model.
    *   Used by `start-sglang.sh` and `test_sglang_model.sh` to filter model lists.

*   **`detect_gpus.py`**:
    *   A Python utility script that detects the number of available NVIDIA GPUs on the system.
    *   Used by `start-sglang.sh` and `benchmark.sh` to automatically configure the `--tensor-parallel-size` for the SGLang server.

*   **`LICENSE`**:
    *   Contains the licensing information for this suite of scripts.

## Setup and Configuration

1.  **Populate `model.txt`**:
    *   Edit the `model.txt` file. Add the Hugging Face model identifiers you wish to work with, ensuring each identifier is on a new line. For example:
        ```
        Qwen/Qwen3-235B-A22B
        deepseek-ai/DeepSeek-R1-0528
        mistralai/Mistral-7B-Instruct-v0.1
        ```

2.  **Make Scripts Executable**:
    *   It's recommended to make the shell scripts executable for easier use:
        ```bash
        chmod +x *.sh
        ```

## Usage Instructions (Workflow)

### Step 1: Initial Environment Setup and Model Download (`setup-sglang.sh`)

This script prepares your environment and downloads the necessary models.

*   **Command:**
    ```bash
    bash setup-sglang.sh
    ```
*   **Interaction:**
    1.  The script performs checks for Python 3, NVIDIA drivers, and a compatible CUDA Toolkit (e.g., 12.1+). It may prompt to install the CUDA toolkit if missing.
    2.  It will create a Python virtual environment (if it doesn't exist) and install required Python packages.
    3.  It will list models found in `model.txt`.
    4.  For each model, it will ask if you want to download it (e.g., `Download model 'Qwen/Qwen3-235B-A22B'? (y/n):`).
*   **Outcome:**
    *   NVIDIA drivers and CUDA Toolkit are verified (or installation attempted).
    *   A Python virtual environment (`venv`) is created and populated.
    *   Required Python packages and system libraries (like `libnuma1`) are installed.
    *   Selected Hugging Face models are downloaded to your local Hugging Face cache.
    *   The script will instruct you to run `start-sglang.sh` to launch the server.

### Step 2: Launching the SGLang Server (`start-sglang.sh`)

After running the setup script, use this script to start the SGLang server.

*   **Command:**
    ```bash
    bash start-sglang.sh
    ```
*   **Interaction:**
    1.  The script will activate the Python virtual environment.
    2.  It will read models from `model.txt` and check which ones are locally cached using `check_model_cached.py`.
    3.  It will prompt you to select one of the locally cached models to launch the SGLang server with.
*   **Outcome:**
    *   An SGLang server instance is started with the model you chose, configured for the detected number of GPUs, listening on `0.0.0.0:30000` by default.

### Step 3: Testing the Server (`test_sglang_model.sh`)

Once the SGLang server is running (launched via `start-sglang.sh`), you can use this script to send test prompts.

*   **Command (Interactive Model Selection):**
    ```bash
    bash test_sglang_model.sh
    ```
    This will prompt you to select a model from `model.txt` (ensure the server is running with this model).
*   **Command (Specify Model Directly):**
    ```bash
    bash test_sglang_model.sh <MODEL_IDENTIFIER_ON_SERVER>
    ```
    Replace `<MODEL_IDENTIFIER_ON_SERVER>` with the ID of the model currently running on the SGLang server (e.g., `Qwen/Qwen3-235B-A22B`).
*   **Interaction:**
    1.  If no model ID is provided as an argument, it reads models from `model.txt`, filters them for locally cached ones using `check_model_cached.py`, and then prompts you to select one of these cached models.
    2.  Prompts to choose the execution mode for API calls: "Sequential" or "Parallel".
*   **Outcome:**
    *   The script sends a series of questions to the SGLang server and prints the model's responses. If `jq` is installed, JSON output will be pretty-printed.

### Step 4: Benchmarking Performance (`benchmark.sh`)

This script is used to evaluate the performance of a model on SGLang.

*   **Command:**
    ```bash
    bash benchmark.sh
    ```
*   **Interaction:**
    1.  The script will prompt you to select a model from `model.txt` to benchmark.
*   **Note:** `benchmark.sh` starts and stops its own SGLang server instance for the chosen model. You do not need a separate server running for this script.
*   **Outcome:**
    *   Performance metrics (requests/second, token throughput, etc.) are logged to `sglang_benchmark_results.log`.
    *   Any errors during the benchmark are logged to `sglang_benchmark_errors.log`.
    *   Key summary metrics are printed to the console upon completion.

### Utility Scripts

*   **`check_model_cached.py`**:
    *   This Python script is used by `start-sglang.sh` and `test_sglang_model.sh` to determine if a Hugging Face model (specifically its `config.json`) is present in the local cache.
    *   It requires the `huggingface_hub` Python library to be accessible.

*   **`detect_gpus.py`**:
    *   This Python script detects the number of available NVIDIA GPUs.
    *   It is used by `start-sglang.sh` and `benchmark.sh` to configure tensor parallelism.
*   **Direct Usage (Optional for `detect_gpus.py`):**
    ```bash
    python detect_gpus.py
    ```
    This will print the number of NVIDIA GPUs detected on your system.

## Customization

*   **Adding Test Questions:**
    *   To modify or add test questions for `test_sglang_model.sh`, edit the `QUESTIONS` array within the script file itself.
*   **Benchmark Parameters:**
    *   The `benchmark.sh` script has several configurable parameters at the top of the file, such as:
        *   `NUM_PROMPTS`: Total number of prompts to send.
        *   `MAX_CONCURRENCY`: Maximum number of concurrent requests.
        *   `INPUT_LEN_AVG`, `OUTPUT_LEN_AVG`: Average token lengths for random prompt generation.
        *   Adjust these as needed for your benchmarking scenario.

## Troubleshooting

*   **"Error: model.txt not found!"**:
    *   Ensure the `model.txt` file exists in the same directory as the script you are running and is populated with model identifiers.
*   **"Error: detect_gpus.py not found..."**:
    *   Ensure `detect_gpus.py` is present in the same directory as `start-sglang.sh` or `benchmark.sh`.
*   **"Error: check_model_cached.py not found..."**:
    *   Ensure `check_model_cached.py` is present in the same directory as `start-sglang.sh` or `test_sglang_model.sh`.
*   **Python / `huggingface_hub` issues for `check_model_cached.py`**:
    *   The `check_model_cached.py` script requires a Python interpreter and the `huggingface_hub` library. If `start-sglang.sh` (which runs in a venv) works but `test_sglang_model.sh` (if run outside the venv) fails to check cached models, ensure `huggingface_hub` is accessible to the Python interpreter being used by `test_sglang_model.sh`.
*   **CUDA Toolkit Issues**:
    *   If `setup-sglang.sh` fails to install the CUDA toolkit, or if you skip the automatic installation, ensure you have a compatible version (12.1+ recommended) installed and correctly configured in your system's PATH and LD_LIBRARY_PATH.
*   **Permission Denied**:
    *   If you encounter permission errors when running `.sh` files, make them executable: `chmod +x script_name.sh`.
*   **Model Download Issues**:
    *   Ensure you are logged into Hugging Face CLI (`huggingface-cli login`) if required for the models you are trying to download.
    *   Check your internet connection.

## License

This project is licensed under the terms detailed in the `LICENSE` file.
