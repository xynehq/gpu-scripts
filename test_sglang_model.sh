#!/bin/bash

# Script to test an LLM running on an SGLang server.

# --- Configuration ---
SGLANG_ENDPOINT="http://localhost:30000/v1/chat/completions"
TEMPERATURE=0.6
TOP_P=0.95
TOP_K=20
MAX_TOKENS=2048 # Adjusted to a more common default, can be overridden if needed.

# --- Questions Array ---
# Add more questions here as needed
QUESTIONS=(
    "Give me a short introduction to large language models."
    "What are the key benefits of using Python for data science?"
    "Write a short poem about a curious cat exploring a new city."
    "Explain the concept of a 'for loop' in programming as if you were talking to a 5-year-old."
    "What is the capital of France and what are three famous landmarks there?"
    "Translate 'Hello, how are you?' into Spanish."
    "Summarize the plot of the movie 'Inception' in two sentences."
    "What are the main differences between renewable and non-renewable energy sources?"
    "Write a simple Python function to calculate the factorial of a number."
    "Describe the process of photosynthesis in simple terms."
    "What are three common data structures used in computer science?"
    "Translate 'Thank you very much' into German."
    "Summarize the story of 'Romeo and Juliet' in three sentences."
    "What is the significance of the Turing Test in artificial intelligence?"
    "Name two advantages and two disadvantages of social media."
    "Write a haiku about the changing seasons."
    "Explain the concept of 'supply and demand' in economics."
    "What is the chemical symbol for water and what does it stand for?"
    "Translate 'Good morning, have a nice day!' into French."
    "Briefly explain the Big Bang Theory."
    "What are the primary colors and why are they called that?"
    "Write a short dialogue between a robot and a human discussing the future."
    "What is the difference between a compiler and an interpreter?"
    "Name three countries in South America and their capitals."
    "Translate 'Where is the nearest library?' into Japanese."
    "What is Moore's Law?"
    "Describe a common use case for blockchain technology beyond cryptocurrencies."
    "Write a limerick about a programmer."
    "What is the role of a CPU in a computer?"
    "Explain the concept of 'gravity' to a child."
    "Translate 'I love learning new things' into Italian."
    "What are the five senses?"
    "What is the difference between weather and climate?"
    "Write a short story (3-4 sentences) about an astronaut discovering a new planet."
    "What is an API and how is it used?"
    "Name the planets in our solar system in order from the Sun."
    "Translate 'This is delicious!' into Korean."
    "What is the importance of biodiversity?"
    "Explain the concept of 'recursion' in programming with a simple example."
    "Write a short thank-you note."
    "What is the difference between HTTP and HTTPS?"
    "Name three famous inventors and one of their inventions."
    "Translate 'Can you help me, please?' into Mandarin Chinese (Pinyin)."
    "What is the purpose of a version control system like Git?"
    "Describe the water cycle."
    "Write a short joke."
    "What is the difference between RAM and ROM?"
    "Name two types of renewable energy."
    "Translate 'See you later' into Portuguese."
    "What is a common algorithm for sorting a list of numbers?"
)

# --- Script Logic ---

MODEL_ID="$1"
EXECUTION_MODE="sequential" # Default execution mode
MODEL_FILE="model.txt"

if [ -z "$MODEL_ID" ]; then
    if [ ! -f "$MODEL_FILE" ]; then
        echo "Error: $MODEL_FILE not found!"
        exit 1
    fi

    echo "Reading models from $MODEL_FILE..."
    mapfile -t MODELS_FROM_FILE < "$MODEL_FILE"

    if [ ${#MODELS_FROM_FILE[@]} -eq 0 ]; then
        echo "No models found in $MODEL_FILE. Exiting."
        exit 1
    fi

    DEFAULT_MODELS=("${MODELS_FROM_FILE[@]}" "Quit")

    echo "No model ID provided. Please select a model to test:"
    select opt in "${DEFAULT_MODELS[@]}"; do
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

# Ask user for execution mode
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
            echo "Running requests in parallel. Output may be interleaved."
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
            echo "--- Request for question $((i+1)) sent ---" 
            # Note: In parallel mode, this line might appear before the actual curl output for this request.
        ) &
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
