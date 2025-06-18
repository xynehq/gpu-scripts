# Detailed File Descriptions

This section provides a detailed description of each file in the project.

*   **`model.txt`**:
    *   A plain text file where you list Hugging Face model identifiers (e.g., `Qwen/Qwen3-30B-A3B`), with one model per line. This file is crucial as it's used by other scripts to determine which models to download, launch, or test.

*   **`setup-sglang.sh`**:
    *   This script automates the initial environment setup, including CUDA checks, `nvitop` installation, and model download process. It:
        *   Checks for Python 3.
        *   Verifies NVIDIA driver installation (via `nvidia-smi`).
        *   Checks for a compatible CUDA Toolkit (target version 12.1 or newer via `nvcc`). If not found or insufficient, it may offer to install `cuda-toolkit-12-1` with user permission.
        *   Creates or verifies a Python virtual environment (`venv`).
        *   Installs SGLang, `huggingface_hub[cli]`, and `nvitop` into the virtual environment.
        *   Installs system dependencies like `libnuma1` (if `apt-get` is available).
        *   Reads model identifiers from `model.txt`.
        *   Prompts the user to confirm the download for each model listed using `huggingface-cli` from the activated virtual environment.
        *   Guides the user to run `start-sglang.sh` to launch the server.

*   **`start-sglang.sh`**:
    *   This script launches the SGLang server. It:
        *   Activates the Python virtual environment.
        *   Reads model identifiers from `model.txt` and uses `scripts/check_model_cached.py` to filter for locally cached models.
        *   Prompts the user to select one of these cached models.
        *   Uses `scripts/detect_gpus.py` to determine the number of available GPUs.
        *   Launches the SGLang server with the selected model, detected GPU count, and configured host/port (defaults to `0.0.0.0:30000`).

*   **`test_sglang_model.sh`**:
    *   Allows interactive testing of a running SGLang server. Questions are read from `queries.txt`.
    *   If no model ID is provided as an argument, it reads models from `model.txt` and uses `scripts/check_model_cached.py` to filter for locally cached models, then presents these for selection.
    *   Supports both sequential and parallel API calls.
    *   For parallel mode, it offers an option to specify the number of concurrent requests per batch, pausing for user confirmation before starting the next batch. Sequential mode runs all questions without batching.

*   **`benchmark.sh`**:
    *   Benchmarks the performance (e.g., throughput, latency) of a selected model running on an SGLang server.
    *   Reads model identifiers from `model.txt` for user selection. (Note: This script does not currently filter by cached models, it assumes the selected model is available).
    *   **Note:** This script manages its own SGLang server instance for the duration of the benchmark, starting it with the selected model and stopping it afterward.
    *   Logs results to `sglang_benchmark_results.log` and errors to `sglang_benchmark_errors.log`.

*   **`scripts/check_model_cached.py`**:
    *   A Python utility script that checks if a given Hugging Face model ID is present in the local cache.
    *   It uses the `huggingface_hub` library to look for `config.json` of the model.
    *   Used by `start-sglang.sh` and `test_sglang_model.sh` to filter model lists.
    *   Located in the `scripts/` directory.

*   **`scripts/detect_gpus.py`**:
    *   A Python utility script that detects the number of available NVIDIA GPUs on the system.
    *   Used by `start-sglang.sh` to help configure the `--tensor-parallel-size`. (`benchmark.sh` currently uses SGLang's default tensor parallelism).
    *   Located in the `scripts/` directory.

*   **`queries.txt`**:
    *   A plain text file containing a list of questions (one per line, ~500 questions) used by `test_sglang_model.sh` for sending prompts to the SGLang server. Allows for easy customization and expansion of the test query set.

*   **`LICENSE`**:
    *   Contains the Apache License 2.0 licensing information for this suite of scripts.

*   **`docs/`**:
    *   A directory intended for more detailed documentation. This includes guides for prerequisites, setup, usage, customization, and troubleshooting.
