#!/bin/bash

# Script to test an LLM running on a vLLM server.

# --- Configuration ---
VLLM_ENDPOINT="http://localhost:8000/v1/chat/completions"
TEMPERATURE=0.6
TOP_P=0.95
TOP_K=20
MAX_TOKENS=2048

# --- Questions are now read from queries.txt ---
QUERIES_FILE="queries.txt"
QUESTIONS=() # Initialize as empty array

# --- Script Logic ---

# Trap for interrupt signals (Ctrl+C, kill)
cleanup_and_exit() {
    echo "" # Newline for cleaner output
    echo "Interrupt received. Cleaning up..."

    # Kill child processes (backgrounded curl commands)
    if command -v pgrep &> /dev/null && command -v xargs &> /dev/null; then
        CHILD_PIDS=$(pgrep -P $$)
        if [ -n "$CHILD_PIDS" ]; then
            echo "Attempting to terminate child processes: $CHILD_PIDS"
            echo "$CHILD_PIDS" | xargs -r kill
        else
            echo "No child processes found to terminate."
        fi
    else
        echo "pgrep or xargs not found, cannot automatically terminate child processes."
    fi

    echo "Exiting script due to interrupt."
    exit 130 # Standard exit code for Ctrl+C
}

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

# If no model ID provided, use the one from the command line argument or default
if [ -z "$MODEL_ID" ]; then
    echo "No model ID provided as argument."
    echo "Enter the model ID (e.g., zai-org/GLM-4.5V-FP8) or press Enter to use default:"
    read -r user_input
    if [ -z "$user_input" ]; then
        MODEL_ID="zai-org/GLM-4.5V-FP8"
        echo "Using default model: $MODEL_ID"
    else
        MODEL_ID="$user_input"
    fi
    echo "" # Newline after input
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

echo "Testing vLLM server at: $VLLM_ENDPOINT"
echo "Using Model ID: $MODEL_ID"
echo "Temperature: $TEMPERATURE, Top P: $TOP_P, Top K: $TOP_K, Max Tokens: $MAX_TOKENS"
echo "Number of questions to ask: ${#QUESTIONS[@]}"
echo "--------------------------------------------------"
echo ""

for i in "${!QUESTIONS[@]}"; do
    QUESTION_CONTENT="${QUESTIONS[$i]}"

    # Escape special characters in QUESTION_CONTENT for JSON
    ESCAPED_QUESTION_CONTENT=$(echo "$QUESTION_CONTENT" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\n/\\n/g; s/\r/\\r/g; s/\t/\\t/g; s/\f/\\f/g; s/\b/\\b/g')

    echo "Question $((i+1)) of ${#QUESTIONS[@]}: $QUESTION_CONTENT"
    echo "---"

    # Construct JSON payload
    JSON_PAYLOAD=$(cat <<EOF
{
  "model": "$MODEL_ID",
  "messages": [
    {"role": "user", "content": "$ESCAPED_QUESTION_CONTENT"}
  ],
  "temperature": $TEMPERATURE,
  "top_p": $TOP_P,
  "top_k": $TOP_K,
  "max_tokens": $MAX_TOKENS
}
EOF
)

    echo "Sending request to vLLM server..."

    # Execute curl command
    if [ "$EXECUTION_MODE" = "sequential" ]; then
        if command -v jq &> /dev/null; then
            curl -s -X POST "$VLLM_ENDPOINT" \
                 -H "Content-Type: application/json" \
                 -d "$JSON_PAYLOAD" | jq .
        else
            echo "jq not found, printing raw JSON response."
            curl -s -X POST "$VLLM_ENDPOINT" \
                 -H "Content-Type: application/json" \
                 -d "$JSON_PAYLOAD"
        fi
        echo ""
        echo "--------------------------------------------------"
    else # Parallel execution
        ( # Subshell for parallel execution
            if command -v jq &> /dev/null; then
                curl -s -X POST "$VLLM_ENDPOINT" \
                     -H "Content-Type: application/json" \
                     -d "$JSON_PAYLOAD" | jq .
            else
                echo "jq not found, printing raw JSON response for question $((i+1))."
                curl -s -X POST "$VLLM_ENDPOINT" \
                     -H "Content-Type: application/json" \
                     -d "$JSON_PAYLOAD"
            fi
            echo ""
            echo "--- Request for question $((i+1)) sent (PID: $$) ---"
        ) &

        # Parallel batching logic
        if [ "$PARALLEL_BATCH_SIZE" -gt 0 ]; then
            current_question_number=$((i + 1))
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

    echo ""
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
