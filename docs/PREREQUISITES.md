# Prerequisites

Before using these scripts, ensure your system meets the following requirements:

*   **Operating System:** Linux-based (due to `apt-get` for package installation).
*   **Python:** Python 3 and `pip3` installed.
*   **Permissions:** `sudo` privileges are required for installing system packages (e.g., `libnuma1`).
*   **Hardware:** 
    *   NVIDIA GPUs and their corresponding drivers are necessary for SGLang to run with GPU acceleration.
    *   A compatible CUDA Toolkit (version 12.1 or newer is recommended) must be installed. The `setup-sglang.sh` script attempts to verify this and can assist with installation on Debian/Ubuntu-based systems.
*   **Internet:** An active internet connection is needed for downloading Python packages and Hugging Face models.
*   **`jq` (Optional):** For pretty-printing JSON responses in `test_sglang_model.sh`. Install via `sudo apt-get install jq`.
*   **`nvitop` (Optional but Recommended):** For GPU monitoring. Installed into the virtual environment by `setup-sglang.sh`.
