#!/bin/bash

# --- Configuration ---
# MODEL_PATH will be selected from model.txt
SGLANG_PORT=30000
NUM_PROMPTS=1000      # Number of requests to send
MAX_CONCURRENCY=64    # Number of concurrent requests
INPUT_LEN_AVG=256     # Average input token length
OUTPUT_LEN_AVG=512    # Average output token length
LOG_FILE="sglang_benchmark_results.log"
ERROR_LOG="sglang_benchmark_errors.log"

MODEL_FILE="model.txt"

if [ ! -f "$MODEL_FILE" ]; then
    echo "Error: $MODEL_FILE not found!"
    exit 1
fi

echo "Reading models from $MODEL_FILE..."
mapfile -t MODELS_FOR_BENCHMARK < "$MODEL_FILE"

if [ ${#MODELS_FOR_BENCHMARK[@]} -eq 0 ]; then
    echo "No models found in $MODEL_FILE. Exiting."
    exit 1
fi

echo "--- Select Model for Benchmark ---"
echo "Please select a model to use for the benchmark:"
select MODEL_PATH in "${MODELS_FOR_BENCHMARK[@]}"; do
    if [[ -n "$MODEL_PATH" ]]; then
        echo "You selected: $MODEL_PATH"
        break
    else
        echo "Invalid selection. Please try again."
    fi
done

if [ -z "$MODEL_PATH" ]; then
    echo "No model selected for benchmark. Exiting."
    exit 1
fi
echo ""


# --- Start SGLang Server ---
echo "Starting SGLang server on port $SGLANG_PORT with model $MODEL_PATH..."
python3 -m sglang.launch_server \
    --model-path "$MODEL_PATH" \
    --port "$SGLANG_PORT" \
    --trust-remote-code \
    --enable-torch-compile \
    --torch-compile-max-bs 256 \
    > "$LOG_FILE" 2>&1 & # Redirect stdout and stderr to log file in background
SERVER_PID=$!
echo "SGLang server started with PID: $SERVER_PID"

# Give the server some time to start up
echo "Waiting for server to warm up (30 seconds)..."
sleep 30

# --- Run SGLang Client Benchmark ---
echo "Running SGLang client benchmark..."
python3 -m sglang.bench_serving \
    --backend sglang \
    --num-prompt "$NUM_PROMPTS" \
    --max-concurrency "$MAX_CONCURRENCY" \
    --random-input "$INPUT_LEN_AVG" \
    --random-output "$OUTPUT_LEN_AVG" \
    --host "127.0.0.1" \
    --port "$SGLANG_PORT" \
    >> "$LOG_FILE" 2>> "$ERROR_LOG" # Append stdout to log, stderr to error log

BENCHMARK_EXIT_CODE=$?

# --- Stop SGLang Server ---
echo "Stopping SGLang server (PID: $SERVER_PID)..."
kill "$SERVER_PID"
wait "$SERVER_PID" 2>/dev/null # Wait for the process to actually terminate
echo "SGLang server stopped."

# --- Report Results ---
if [ $BENCHMARK_EXIT_CODE -eq 0 ]; then
    echo "Benchmark completed successfully."
    echo "Results can be found in $LOG_FILE"
    echo "Relevant metrics (Requests/s, Output tokens/s, Total tokens/s) are usually at the end of the log."
    grep -E "Request throughput|Output token throughput|Total Token throughput" "$LOG_FILE" | tail -n 3
else
    echo "Benchmark failed with exit code $BENCHMARK_EXIT_CODE."
    echo "Check $LOG_FILE and $ERROR_LOG for details."
fi

echo "Done."
