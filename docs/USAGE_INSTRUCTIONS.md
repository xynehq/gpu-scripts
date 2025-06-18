# Usage Instructions (Workflow)

This section outlines the typical workflow for using the scripts.

## Step 1: Initial Environment Setup and Model Download (`setup-sglang.sh`)

This script prepares your environment, installs dependencies (including SGLang, `huggingface_hub`, and `nvitop` into a Python virtual environment), checks for CUDA, and downloads the necessary models.

*   **Command:**
    ```bash
    bash setup-sglang.sh
    ```
    Or, if you've made it executable:
    ```bash
    ./setup-sglang.sh
    ```

*   **Interaction:**
    1.  The script performs checks for Python 3, NVIDIA drivers, and a compatible CUDA Toolkit (e.g., 12.1+). It may prompt to install the CUDA toolkit if missing and `apt` is available.
    2.  It will create a Python virtual environment (`venv/`) if it doesn't exist and install required Python packages.
    3.  It will list models found in `model.txt`.
    4.  For each model, it will ask if you want to download it (e.g., `Download model 'Qwen/Qwen3-235B-A22B'? (y/n):`).
*   **Outcome:**
    *   NVIDIA drivers and CUDA Toolkit are verified (or installation attempted).
    *   A Python virtual environment (`venv/`) is created and populated with SGLang, `huggingface_hub`, `nvitop`, and their dependencies.
    *   System libraries like `libnuma1` are installed (if using `apt`).
    *   Selected Hugging Face models are downloaded to your local Hugging Face cache.
    *   The script will instruct you to run `start-sglang.sh` to launch the server.

## Step 2: Launching the SGLang Server (`start-sglang.sh`)

After running the setup script, use this script to start the SGLang server.

*   **Command:**
    ```bash
    bash start-sglang.sh
    ```
    Or, if executable:
    ```bash
    ./start-sglang.sh
    ```

*   **Interaction:**
    1.  The script will activate the `venv/` virtual environment.
    2.  It will read models from `model.txt` and check which ones are locally cached using `scripts/check_model_cached.py`.
    3.  It will prompt you to select one of the locally cached models to launch the SGLang server with.
*   **Outcome:**
    *   An SGLang server instance is started with the model you chose, configured for the detected number of GPUs (using `scripts/detect_gpus.py`), listening on `0.0.0.0:30000` by default.
    *   You can monitor the GPU usage with `nvitop` (run in a separate terminal after activating the venv: `source venv/bin/activate && nvitop`).

## Step 3: Testing the Server (`test_sglang_model.sh`)

Once the SGLang server is running (launched via `start-sglang.sh`), you can use this script to send test prompts from `queries.txt`.

*   **Command (Interactive Model Selection):**
    ```bash
    bash test_sglang_model.sh
    ```
    Or, if executable:
    ```bash
    ./test_sglang_model.sh
    ```
    This will activate the venv, check cached models from `model.txt`, and prompt you to select one.
*   **Command (Specify Model Directly):**
    ```bash
    bash test_sglang_model.sh <MODEL_IDENTIFIER_ON_SERVER>
    ```
    Or:
    ```bash
    ./test_sglang_model.sh <MODEL_IDENTIFIER_ON_SERVER>
    ```
    Replace `<MODEL_IDENTIFIER_ON_SERVER>` with the ID of the model currently running on the SGLang server (e.g., `Qwen/Qwen3-235B-A22B`).
*   **Interaction:**
    1.  If no model ID is provided as an argument, it reads models from `model.txt`, filters them for locally cached ones using `scripts/check_model_cached.py`, and then prompts you to select one of these cached models.
    2.  Prompts to choose the execution mode for API calls: "Sequential" or "Parallel".
    3.  If "Parallel" mode is chosen, it will further prompt for the number of parallel requests per batch (e.g., 10; 0 for no limit). If batching is used (batch size > 0), it will pause for user input after each batch of parallel requests completes.
*   **Outcome:**
    *   The script sends a series of questions from `queries.txt` to the SGLang server and prints the model's responses. If `jq` is installed, JSON output will be pretty-printed.

## Step 4: Benchmarking Performance (`benchmark.sh`)

This script is used to evaluate the performance of a model on SGLang.

*   **Command:**
    ```bash
    bash benchmark.sh
    ```
    Or, if executable:
    ```bash
    ./benchmark.sh
    ```
*   **Interaction:**
    1.  The script will prompt you to select a model from `model.txt` to benchmark.
*   **Note:** `benchmark.sh` starts and stops its own SGLang server instance for the chosen model. You do not need a separate server running for this script. It activates the `venv/` to ensure it uses the correct Python and SGLang installation.
*   **Outcome:**
    *   Performance metrics (requests/second, token throughput, etc.) are logged to `sglang_benchmark_results.log`.
    *   Any errors during the benchmark are logged to `sglang_benchmark_errors.log`.
    *   Key summary metrics are printed to the console upon completion.

## Utility Scripts (`scripts/` directory)

The scripts in the `scripts/` directory are generally used internally by the main scripts.

*   **`scripts/check_model_cached.py`**:
    *   Used by `start-sglang.sh` and `test_sglang_model.sh` to verify if models are locally cached.
*   **`scripts/detect_gpus.py`**:
    *   Used by `start-sglang.sh` to determine GPU count for tensor parallelism.
    *   Direct Usage (Optional):
        ```bash
        source venv/bin/activate # If not already active
        python scripts/detect_gpus.py
        deactivate # If you activated it just for this
        ```
        This will print the number of NVIDIA GPUs detected on your system.
