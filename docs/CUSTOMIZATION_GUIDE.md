# Customization Guide

This section provides information on how to customize the behavior of the scripts.

## Test Questions (`queries.txt`)

*   The test questions used by `test_sglang_model.sh` are sourced from the `queries.txt` file located in the root directory of the project.
*   This file contains a large default list of diverse questions (approximately 500).
*   **To modify, add, or replace the test questions:**
    *   Edit the `queries.txt` file directly.
    *   Ensure each question is on a new line.
    *   Empty lines or lines starting with a `#` (which can be used for comments) in `queries.txt` will be ignored by the `test_sglang_model.sh` script.

## Benchmark Parameters (`benchmark.sh`)

*   The `benchmark.sh` script has several configurable parameters defined at the top of the file. You can modify these to suit your benchmarking needs:
    *   `SGLANG_PORT`: The port on which the benchmark script will temporarily launch its own SGLang server instance. Defaults to `30000`.
    *   `NUM_PROMPTS`: Total number of prompts to send during the benchmark. Defaults to `1000`.
    *   `MAX_CONCURRENCY`: Maximum number of concurrent requests to simulate. Defaults to `64`.
    *   `INPUT_LEN_AVG`: Average input token length for randomly generated prompts. Defaults to `256`.
    *   `OUTPUT_LEN_AVG`: Average output token length for randomly generated prompts. Defaults to `512`.
    *   `LOG_FILE`: Path to the file where benchmark results will be logged. Defaults to `sglang_benchmark_results.log`.
    *   `ERROR_LOG`: Path to the file where benchmark errors will be logged. Defaults to `sglang_benchmark_errors.log`.
*   Adjust these parameters as needed for your specific benchmarking scenario.

## SGLang Server Parameters (`test_sglang_model.sh`)

*   The `test_sglang_model.sh` script uses predefined parameters when sending requests to the SGLang server. These are defined at the top of the script:
    *   `SGLANG_ENDPOINT`: The endpoint of the running SGLang server. Defaults to `http://localhost:30000/v1/chat/completions`.
    *   `TEMPERATURE`: Sampling temperature. Defaults to `0.6`.
    *   `TOP_P`: Nucleus sampling (top-p). Defaults to `0.95`.
    *   `TOP_K`: Top-k sampling. Defaults to `20`.
    *   `MAX_TOKENS`: Maximum number of tokens to generate. Defaults to `2048`.
*   You can modify these default values directly in the script if you wish to test with different generation parameters.

## SGLang Server Launch Parameters (`start-sglang.sh`)
*   The `start-sglang.sh` script launches the SGLang server with some default parameters like `--host "0.0.0.0"` and `--port 30000`.
*   If you need to change these or add other SGLang server arguments (e.g., `--log-level`, `--chat-template`), you can modify the `python -m sglang.launch_server ...` line within `start-sglang.sh`.
