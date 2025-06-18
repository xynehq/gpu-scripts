#!/bin/bash

# Script to test an LLM running on an SGLang server.

# --- Configuration ---
SGLANG_ENDPOINT="http://localhost:30000/v1/chat/completions"
TEMPERATURE=0.6
TOP_P=0.95
TOP_K=20
MAX_TOKENS=2048 # Adjusted to a more common default, can be overridden if needed.

# --- Questions are now read from queries.txt ---
QUERIES_FILE="queries.txt"
QUESTIONS=() # Initialize as empty array

# --- Script Logic ---

VENV_DIR="venv"

# Check if virtual environment exists and activate it
if [ ! -d "$VENV_DIR" ]; then
    echo "Error: Python virtual environment not found in $VENV_DIR."
    echo "Please run the setup script (./setup-sglang.sh) first to create the virtual environment."
    exit 1
fi

echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"
if [ $? -ne 0 ]; then
    echo "Failed to activate virtual environment. Exiting."
    # Attempt to deactivate if source failed mid-way, though unlikely for source
    if command -v deactivate &> /dev/null; then
        deactivate
    fi
    exit 1
fi

# Trap to ensure deactivation on exit, error, or interrupt
cleanup_and_exit() {
    echo "" # Newline for cleaner output
    echo "Interrupt received. Cleaning up..."
    
    # Kill child processes (backgrounded curl commands)
    # pgrep -P $$ will list PIDs of children of the current script (PID $$)
    # xargs kill will kill them. Add -r to xargs to not run if no PIDs.
    # Check if pgrep and xargs are available
    if command -v pgrep &> /dev/null && command -v xargs &> /dev/null; then
        # Get child PIDs. If script is run with "bash script.sh", $$ is the PID of bash.
        # If script is run with "./script.sh", $$ is the PID of the script itself.
        # This should work in both cases for direct children.
        CHILD_PIDS=$(pgrep -P $$)
        if [ -n "$CHILD_PIDS" ]; then
            echo "Attempting to terminate child processes: $CHILD_PIDS"
            # Send SIGTERM first, then SIGKILL if necessary after a short delay (not implemented here for simplicity)
            # Using kill without signal sends SIGTERM by default.
            echo "$CHILD_PIDS" | xargs -r kill 
        else
            echo "No child processes found to terminate."
        fi
    else
        echo "pgrep or xargs not found, cannot automatically terminate child processes."
    fi
    
    if command -v deactivate &> /dev/null; then
        echo "Deactivating virtual environment..."
        deactivate
    else
        echo "Warning: 'deactivate' command not found, cannot deactivate virtual environment."
    fi
    echo "Exiting script due to interrupt."
    exit 130 # Standard exit code for Ctrl+C
}

# Trap for normal exit (cleans up venv)
trap 'if command -v deactivate &> /dev/null; then echo "Deactivating virtual environment (normal exit)..."; deactivate; fi' EXIT

# Trap for interrupt signals (Ctrl+C, kill)
trap cleanup_and_exit SIGINT SIGTERM

# Read questions from queries.txt
if [ ! -f "$QUERIES_FILE" ]; then
    echo "Error: Queries file not found at $QUERIES_FILE"
    echo "Please create it and populate it with questions, one per line."
    exit 1
fi

mapfile -t QUESTIONS < "$QUERIES_FILE"

# Remove any empty lines that mapfile might have read
# and filter out lines that are only whitespace or comments starting with #
TEMP_QUESTIONS=()
for i in "${!QUESTIONS[@]}"; do
    # Remove leading/trailing whitespace
    line_trimmed=$(echo "${QUESTIONS[$i]}" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    # Skip empty lines or lines starting with #
    if [[ -n "$line_trimmed" && ! "$line_trimmed" =~ ^# ]]; then
        TEMP_QUESTIONS+=("$line_trimmed")
    fi
done
QUESTIONS=("${TEMP_QUESTIONS[@]}") # Assign back the cleaned and filtered questions

if [ ${#QUESTIONS[@]} -eq 0 ]; then
    echo "No valid questions found in $QUERIES_FILE. Exiting."
    exit 1
fi

MODEL_ID="$1"
EXECUTION_MODE="sequential" # Default execution mode
MODEL_FILE="model.txt"
CHECK_MODEL_CACHED_SCRIPT="scripts/check_model_cached.py" # Path updated

if [ -z "$MODEL_ID" ]; then
    if [ ! -f "$MODEL_FILE" ]; then
        echo "Error: $MODEL_FILE not found!"
        exit 1
    fi

    echo "Reading potential models from $MODEL_FILE..."
    mapfile -t POTENTIAL_MODELS < "$MODEL_FILE"

    if [ ${#POTENTIAL_MODELS[@]} -eq 0 ]; then
        echo "No models found in $MODEL_FILE. Exiting."
        exit 1
    fi

    if [ ! -f "$CHECK_MODEL_CACHED_SCRIPT" ]; then
        echo "Error: $CHECK_MODEL_CACHED_SCRIPT not found. Cannot verify cached models."
        exit 1
    fi
    if ! command -v python &> /dev/null && ! command -v python3 &> /dev/null; then
        echo "Error: Python interpreter not found. Cannot run $CHECK_MODEL_CACHED_SCRIPT."
        exit 1
    fi
    PYTHON_CMD=$(command -v python3 || command -v python)

    echo "Checking which models from $MODEL_FILE are locally cached..."
    AVAILABLE_MODELS=()
    for model_id_loop in "${POTENTIAL_MODELS[@]}"; do
        # Remove potential trailing whitespace/CR from model_id_loop read by mapfile
        model_id_clean=$(echo "$model_id_loop" | tr -d '[:space:]')
        if [ -z "$model_id_clean" ]; then
            continue
        fi
        
        # Assuming SGLANG_ENDPOINT implies a running server, so venv might not be active here.
        # However, check_model_cached.py needs huggingface_hub.
        # For simplicity, let's assume the user has huggingface_hub in their global python if venv isn't active,
        # or they should run this from an environment where it's available.
        # A more robust solution would be to activate the venv if this script also expects it.
        # For now, using system python or python3.
        if "$PYTHON_CMD" "$CHECK_MODEL_CACHED_SCRIPT" "$model_id_clean"; then
            echo "- $model_id_clean (Cached)"
            AVAILABLE_MODELS+=("$model_id_clean")
        else
            echo "- $model_id_clean (Not cached or config.json missing)"
        fi
    done
    echo ""

    if [ ${#AVAILABLE_MODELS[@]} -eq 0 ]; then
        echo "No locally cached models found from the list in $MODEL_FILE."
        echo "Please ensure models are downloaded (e.g., via ./setup-sglang.sh) and cached."
        exit 1
    fi

    SELECT_OPTIONS=("${AVAILABLE_MODELS[@]}" "Quit")

    echo "No model ID provided. Please select a cached model to test:"
    select opt in "${SELECT_OPTIONS[@]}"; do
        if [ "$opt" = "Quit" ]; then
            echo "Exiting."
            exit 0
        elif [[ -n "$opt" ]]; then
            MODEL_ID="$opt"
            break
        else
            echo "Invalid option $REPLY"
        fi
    done

    if [ -z "$MODEL_ID" ]; then # Should not happen if Quit is selected, but as a safeguard
        echo "No model selected. Exiting."
        exit 1
    fi
    echo "" # Newline after selection
fi

# Ask user for execution mode and parallel batch size if applicable
PARALLEL_BATCH_SIZE=0
echo "Select execution mode for curl requests:"
select mode_opt in "Sequential" "Parallel"; do
    case $mode_opt in
        "Sequential")
            EXECUTION_MODE="sequential"
            echo "Running requests sequentially."
            break
            ;;
        "Parallel")
            EXECUTION_MODE="parallel"
            echo "Running requests in parallel."
            while true; do
                read -r -p "Enter number of parallel requests per batch (e.g., 10; 0 for no limit - all run concurrently): " BATCH_SIZE_INPUT
                if [[ -z "$BATCH_SIZE_INPUT" ]]; then # Handle empty input as 0 (no limit)
                    PARALLEL_BATCH_SIZE=0
                    echo "No batch size entered, will run all questions in parallel concurrently."
                    break
                elif [[ "$BATCH_SIZE_INPUT" =~ ^[0-9]+$ ]]; then
                    PARALLEL_BATCH_SIZE=$BATCH_SIZE_INPUT
                    if [ "$PARALLEL_BATCH_SIZE" -eq 0 ]; then
                        echo "Batch size 0 selected, will run all questions in parallel concurrently."
                    else
                        echo "Parallel batch size set to $PARALLEL_BATCH_SIZE."
                    fi
                    break
                else
                    echo "Invalid input. Please enter a non-negative integer."
                fi
            done
            break
            ;;
        *) echo "Invalid option $REPLY";;
    esac
done
echo "" # Newline after selection

echo "Testing SGLang server at: $SGLANG_ENDPOINT"
echo "Using Model ID: $MODEL_ID"
echo "Temperature: $TEMPERATURE, Top P: $TOP_P, Top K: $TOP_K, Max Tokens: $MAX_TOKENS"
echo "Number of questions to ask: ${#QUESTIONS[@]}"
echo "--------------------------------------------------"
echo ""

for i in "${!QUESTIONS[@]}"; do
    QUESTION_CONTENT="${QUESTIONS[$i]}"
    
    echo "Question $((i+1)) of ${#QUESTIONS[@]}: $QUESTION_CONTENT"
    echo "---"

    # Construct JSON payload
    # Using heredoc for easier multiline JSON and variable expansion
    JSON_PAYLOAD=$(cat <<EOF
{
  "model": "$MODEL_ID",
  "messages": [
    {"role": "user", "content": "$QUESTION_CONTENT"}
  ],
  "temperature": $TEMPERATURE,
  "top_p": $TOP_P,
  "top_k": $TOP_K,
  "max_tokens": $MAX_TOKENS
}
EOF
)

    echo "Sending request to SGLang server..."
    # echo "Payload: $JSON_PAYLOAD" # Uncomment to debug payload

    # Execute curl command
    # Adding -s for silent mode to suppress progress meter, but show errors
    # If jq is installed, pipe to jq for pretty printing: | jq .
    # Otherwise, print raw JSON.
    if [ "$EXECUTION_MODE" = "sequential" ]; then
        if command -v jq &> /dev/null; then
            curl -s -X POST "$SGLANG_ENDPOINT" \
                 -H "Content-Type: application/json" \
                 -d "$JSON_PAYLOAD" | jq .
        else
            echo "jq not found, printing raw JSON response."
            curl -s -X POST "$SGLANG_ENDPOINT" \
                 -H "Content-Type: application/json" \
                 -d "$JSON_PAYLOAD"
        fi
        echo ""
        echo "--------------------------------------------------"
    else # Parallel execution
        ( # Subshell for parallel execution
            if command -v jq &> /dev/null; then
                curl -s -X POST "$SGLANG_ENDPOINT" \
                     -H "Content-Type: application/json" \
                     -d "$JSON_PAYLOAD" | jq .
            else
                echo "jq not found, printing raw JSON response for question $((i+1))."
                curl -s -X POST "$SGLANG_ENDPOINT" \
                     -H "Content-Type: application/json" \
                     -d "$JSON_PAYLOAD"
            fi
            echo ""
            echo "--- Request for question $((i+1)) sent (PID: $$) ---"
        ) &
        
        # Parallel batching logic
        if [ "$PARALLEL_BATCH_SIZE" -gt 0 ]; then
            # Calculate current question number (1-indexed)
            current_question_number=$((i + 1))
            # Increment job counter (or use modulo for batching)
            # A simple way is to count active jobs, but bash doesn't have a direct way to count background jobs easily from script.
            # Instead, we'll wait after every PARALLEL_BATCH_SIZE jobs are launched.
            if (( current_question_number % PARALLEL_BATCH_SIZE == 0 && current_question_number < ${#QUESTIONS[@]} )); then
                echo ""
                echo "Waiting for current batch of $PARALLEL_BATCH_SIZE parallel requests to complete..."
                wait
                echo "Parallel batch complete."
                read -r -p "Press Enter to process the next batch, or Ctrl+C to exit..."
                echo "--------------------------------------------------"
                echo ""
            fi
        fi
    fi
    
    # No explicit "--------------------------------------------------" here for parallel to avoid clutter before all finish
    # It will be printed after the wait command.
    echo ""

    # Optional: Add a small delay between requests if needed
    # sleep 1
done

if [ "$EXECUTION_MODE" = "parallel" ]; then
    echo ""
    echo "Waiting for all parallel requests to complete..."
    wait
    echo "--------------------------------------------------"
    echo "All parallel requests have completed."
    echo "--------------------------------------------------"
    echo ""
fi

echo "All questions processed."
echo "Script finished."
