# Setup and Configuration

This guide details the necessary steps to set up your environment and configure the scripts.

## 1. Populate `model.txt`

*   Edit the `model.txt` file located in the root directory of the project.
*   Add the Hugging Face model identifiers you wish to work with, ensuring each identifier is on a new line.
*   **Example `model.txt`:**
    ```
    Qwen/Qwen3-235B-A22B
    deepseek-ai/DeepSeek-R1-0528
    mistralai/Mistral-7B-Instruct-v0.1
    ```
*   This file is crucial as it's used by `setup-sglang.sh` for downloading models, and by `start-sglang.sh`, `test_sglang_model.sh`, and `benchmark.sh` for model selection.

## 2. Populate `queries.txt` (for `test_sglang_model.sh`)

*   The `queries.txt` file, located in the root directory, contains the list of questions that `test_sglang_model.sh` will use to send prompts to the SGLang server.
*   A default list of ~500 diverse questions is provided.
*   You can customize this file by adding, removing, or modifying questions. Ensure each question is on a new line.
*   Empty lines or lines starting with a `#` (comment) in `queries.txt` will be ignored by the test script.

## 3. Make Scripts Executable

*   For convenience, it's recommended to make the shell scripts in the root directory executable:
    ```bash
    chmod +x setup-sglang.sh
    chmod +x start-sglang.sh
    chmod +x test_sglang_model.sh
    chmod +x benchmark.sh
    ```
*   The Python utility scripts in the `scripts/` directory (`check_model_cached.py`, `detect_gpus.py`) are also made executable by the system or can be made so if needed, though they are typically called via `python <script_name>`.

## 4. Review Script Configurations (Optional)

*   **`test_sglang_model.sh`**:
    *   `SGLANG_ENDPOINT`: Defaults to `http://localhost:30000/v1/chat/completions`. Adjust if your server runs on a different endpoint.
    *   `TEMPERATURE`, `TOP_P`, `TOP_K`, `MAX_TOKENS`: Default generation parameters. These can be modified at the top of the script if needed for testing.
*   **`benchmark.sh`**:
    *   `SGLANG_PORT`: Port used by the benchmark script to launch its temporary SGLang server.
    *   `NUM_PROMPTS`, `MAX_CONCURRENCY`, `INPUT_LEN_AVG`, `OUTPUT_LEN_AVG`: Parameters controlling the benchmark load.
    *   `LOG_FILE`, `ERROR_LOG`: Paths for benchmark logs.
    *   These can be adjusted at the top of the `benchmark.sh` script.

After these steps, you should be ready to run the main workflow scripts. Refer to the [Usage Instructions](USAGE_INSTRUCTIONS.md) for details on running the scripts.
