# Troubleshooting Guide

This guide provides solutions to common issues you might encounter while using the scripts.

*   **"Error: model.txt not found!"**:
    *   Ensure the `model.txt` file exists in the root directory of the project and is populated with model identifiers. This file is used by `setup-sglang.sh`, `start-sglang.sh`, `test_sglang_model.sh`, and `benchmark.sh`.

*   **"Error: queries.txt not found..." or "No valid questions found..."**:
    *   Ensure `queries.txt` exists in the root directory and contains questions, one per line. `test_sglang_model.sh` relies on this file.

*   **"Error: scripts/detect_gpus.py not found..."**:
    *   Ensure `detect_gpus.py` is present in the `scripts/` directory. This script is used by `start-sglang.sh`.

*   **"Error: scripts/check_model_cached.py not found..."**:
    *   Ensure `check_model_cached.py` is present in the `scripts/` directory. This script is used by `start-sglang.sh` and `test_sglang_model.sh`.

*   **Python / `huggingface_hub` issues for `scripts/check_model_cached.py`**:
    *   The `scripts/check_model_cached.py` script requires a Python interpreter and the `huggingface_hub` library.
    *   `setup-sglang.sh` installs `huggingface_hub` into the `venv/` virtual environment.
    *   Scripts like `start-sglang.sh` and `test_sglang_model.sh` activate this virtual environment, so `check_model_cached.py` should work correctly when called by them.
    *   If you run `scripts/check_model_cached.py` manually or from another script that doesn't activate the `venv`, ensure `huggingface_hub` is accessible to the Python interpreter being used.

*   **CUDA Toolkit Issues**:
    *   **"Error: nvidia-smi command not found..."**: This indicates that NVIDIA drivers are likely not installed correctly or `nvidia-smi` is not in your system's PATH. Install/reinstall drivers for your GPU.
    *   **"nvcc (CUDA Toolkit Compiler Driver) not found..."**: The CUDA Toolkit might not be installed, or `nvcc` is not in your PATH.
    *   `setup-sglang.sh` attempts to check for CUDA Toolkit (version 12.1+ recommended) and can offer to install `cuda-toolkit-12-1` on Debian/Ubuntu systems if `apt` is available and you grant permission.
    *   If automatic installation fails or is skipped, ensure you have a compatible CUDA Toolkit installed and that `nvcc` is in your PATH. You might also need to set `LD_LIBRARY_PATH` correctly. Refer to official NVIDIA documentation for CUDA installation.

*   **`nvitop` issues**:
    *   `nvitop` is installed by `setup-sglang.sh` into the `venv/` virtual environment.
    *   To use it, first activate the virtual environment: `source venv/bin/activate`
    *   Then run: `nvitop`
    *   If you get "command not found", ensure the venv is active.

*   **Permission Denied**:
    *   If you encounter permission errors when running `.sh` files (e.g., `./setup-sglang.sh`), make them executable:
        ```bash
        chmod +x setup-sglang.sh start-sglang.sh test_sglang_model.sh benchmark.sh
        ```
    *   Python scripts in `scripts/` are typically run via `python scripts/script_name.py`, so they don't strictly need execute permissions themselves, but it doesn't hurt to add them (`chmod +x scripts/*.py`).

*   **Model Download Issues**:
    *   Ensure you have an active internet connection.
    *   If you are trying to download private or gated models from Hugging Face, you may need to log in using the Hugging Face CLI:
        ```bash
        source venv/bin/activate  # Ensure you're in the venv where huggingface_hub is
        huggingface-cli login
        ```
    *   Follow the prompts to enter your Hugging Face token.

*   **`deactivate: command not found` (in traps)**:
    *   The scripts `start-sglang.sh` and `test_sglang_model.sh` include `trap` commands to attempt to `deactivate` the virtual environment on exit or interrupt.
    *   If you see "deactivate: command not found" from a trap, it's usually a non-critical warning. The primary function of the trap (like exiting or cleaning up child processes) should still work. This can sometimes occur if the shell environment within the trap context is slightly different. The scripts include checks (`if command -v deactivate`) to minimize these messages.

*   **JSON Payload Errors in `test_sglang_model.sh`**:
    *   If you see "Invalid request body" errors from the SGLang server when running `test_sglang_model.sh`, it might be due to special characters in your `queries.txt` file that are not being properly escaped for JSON.
    *   The script attempts to escape common characters like `"` and `\`. If you encounter persistent issues, review the problematic query in `queries.txt` and simplify any complex characters or ensure they are correctly handled by the escaping logic in `test_sglang_model.sh`.
