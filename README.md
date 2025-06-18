# SGLang Server Management and Testing Utilities

## Overview

This suite of scripts provides utilities for setting up an SGLang (Efficient Language Model Serving) environment, managing language models, launching an SGLang server, testing its functionality, and benchmarking its performance. These scripts are designed to streamline the process of working with various Hugging Face language models via SGLang.

## Prerequisites

Before using these scripts, ensure your system meets the following requirements:

*   **Operating System:** Linux-based (due to `apt-get` for package installation).
*   **Python:** Python 3 and `pip3` installed.
*   **Permissions:** `sudo` privileges are required for installing system packages (e.g., `libnuma1`).
*   **Hardware:** NVIDIA GPUs and their corresponding drivers are necessary for SGLang to run with GPU acceleration.
*   **Internet:** An active internet connection is needed for downloading Python packages and Hugging Face models.
*   **`jq` (Optional):** For pretty-printing JSON responses in `test_sglang_model.sh`. Install via `sudo apt-get install jq`.

## File Descriptions

*   **`model.txt`**:
    *   A plain text file where you list Hugging Face model identifiers (e.g., `Qwen/Qwen3-30B-A3B`), with one model per line. This file is crucial as it's used by other scripts to determine which models to download, launch, or test.

*   **`setup-sglang.sh`**:
    *   This script automates the initial setup process. It:
        *   Installs SGLang, `huggingface_hub[cli]`, and other dependencies like `libnuma1`.
        *   Reads model identifiers from `model.txt`.
        *   Prompts the user to confirm the download for each model listed.
        *   Prompts the user to select one of the downloaded models to launch the SGLang server.
        *   Uses `detect_gpus.py` to configure tensor parallelism based on available GPUs.

*   **`test_sglang_model.sh`**:
    *   Allows interactive testing of a running SGLang server.
    *   Reads model identifiers from `model.txt` to present a selection menu (if no model is passed as an argument).
    *   Sends a predefined list of diverse questions to the selected model.
    *   Supports both sequential and parallel API calls (user-selectable).

*   **`benchmark.sh`**:
    *   Benchmarks the performance (e.g., throughput, latency) of a selected model running on an SGLang server.
    *   Reads model identifiers from `model.txt` for user selection.
    *   **Note:** This script manages its own SGLang server instance for the duration of the benchmark, starting it with the selected model and stopping it afterward.
    *   Logs results to `sglang_benchmark_results.log` and errors to `sglang_benchmark_errors.log`.

*   **`detect_gpus.py`**:
    *   A Python utility script that detects the number of available NVIDIA GPUs on the system.
    *   Used by `setup-sglang.sh` to automatically configure the `--tensor-parallel-size` for the SGLang server.

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

### Step 1: Initial Setup and Server Launch (`setup-sglang.sh`)

This script prepares your environment and starts the SGLang server.

*   **Command:**
    ```bash
    bash setup-sglang.sh
    ```
*   **Interaction:**
    1.  The script will list models found in `model.txt`.
    2.  For each model, it will ask if you want to download it (e.g., `Download model 'Qwen/Qwen3-235B-A22B'? (y/n):`).
    3.  After the download phase, it will prompt you to select one model from the list in `model.txt` to launch the SGLang server with.
*   **Outcome:**
    *   Required Python packages and system libraries are installed.
    *   Selected Hugging Face models are downloaded to your local Hugging Face cache.
    *   An SGLang server instance is started with the model you chose, configured for the detected number of GPUs.

### Step 2: Testing the Server (`test_sglang_model.sh`)

Once the SGLang server is running (typically launched via `setup-sglang.sh`), you can use this script to send test prompts.

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
    1.  If no model ID is provided as an argument, it prompts to select a model from `model.txt`.
    2.  Prompts to choose the execution mode for API calls: "Sequential" or "Parallel".
*   **Outcome:**
    *   The script sends a series of questions to the SGLang server and prints the model's responses. If `jq` is installed, JSON output will be pretty-printed.

### Step 3: Benchmarking Performance (`benchmark.sh`)

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

### Utility Script (`detect_gpus.py`)

This script is mainly for internal use by `setup-sglang.sh`.

*   **Direct Usage (Optional):**
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
    *   Ensure `detect_gpus.py` is present in the same directory as `setup-sglang.sh`.
*   **Permission Denied**:
    *   If you encounter permission errors when running `.sh` files, make them executable: `chmod +x script_name.sh`.
*   **Model Download Issues**:
    *   Ensure you are logged into Hugging Face CLI (`huggingface-cli login`) if required for the models you are trying to download.
    *   Check your internet connection.
