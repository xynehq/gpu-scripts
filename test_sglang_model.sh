#!/bin/bash

# Script to test an LLM running on an SGLang server.

# --- Configuration ---
SGLANG_ENDPOINT="http://localhost:30000/v1/chat/completions"
TEMPERATURE=0.6
TOP_P=0.95
TOP_K=20
MAX_TOKENS=2048 # Adjusted to a more common default, can be overridden if needed.

# --- Questions Array ---
# Expanded list of 200 questions
QUESTIONS=(
    "What is the capital of Australia?"
    "Explain the theory of relativity in simple terms."
    "Write a Python function to reverse a string."
    "Who painted the Mona Lisa?"
    "What are the main components of a cell?"
    "Translate 'Good evening' into Japanese."
    "Summarize the book '1984' in three sentences."
    "What is the difference between AI, ML, and DL?"
    "Compose a short story about a time-traveling historian."
    "What is the chemical formula for glucose?"
    "Name three programming paradigms."
    "Translate 'Where is the bathroom?' into German."
    "What are the primary functions of the human liver?"
    "Describe the concept of 'git rebase'."
    "Write a haiku about a silent forest."
    "What is the significance of the Rosetta Stone?"
    "Explain the OSI model."
    "What is the currency of Switzerland?"
    "Translate 'I need help' into French."
    "What are the symptoms of diabetes?"
    "Write a function in JavaScript to find the maximum element in an array."
    "Who wrote 'Pride and Prejudice'?"
    "What is the process of nuclear fission?"
    "Translate 'How much does this cost?' into Spanish."
    "Describe the architecture of a typical web application."
    "What is a black hole?"
    "Compose a limerick about a clumsy robot."
    "What are the main causes of climate change?"
    "Translate 'My name is [Your Name]' into Italian. (Replace [Your Name] with 'AI')"
    "Explain the concept of 'Big O notation'."
    "What is the capital of Canada?"
    "Write a short poem about the ocean."
    "What is the difference between TCP and UDP?"
    "Who discovered penicillin?"
    "Translate 'What time is it?' into Mandarin Chinese (Pinyin)."
    "What are the stages of the water cycle?"
    "Describe the plot of Shakespeare's 'Hamlet'."
    "What is a quantum computer?"
    "Write a short dialogue between a philosopher and a scientist."
    "Translate 'I am learning a new language' into Portuguese."
    "What is the role of mitochondria in a cell?"
    "Explain the concept of 'agile methodology'."
    "What is the capital of Japan?"
    "Write a Python script to count word occurrences in a text file."
    "Who developed the theory of evolution by natural selection?"
    "Translate 'Pleased to meet you' into Korean."
    "What are the main features of a democratic system?"
    "Describe the structure of DNA."
    "Compose a short horror story (3-4 sentences)."
    "What is the purpose of a firewall?"
    "Translate 'Can I have the bill, please?' into German."
    "Explain the difference between a virus and a bacteria."
    "What is the capital of Brazil?"
    "Write a JavaScript function to check if a number is prime."
    "Who composed 'The Four Seasons' (classical music)?"
    "Translate 'I don't understand' into Spanish."
    "What are the key principles of object-oriented programming?"
    "Describe the process of digestion in the human body."
    "Write a sonnet about the beauty of nature."
    "What is the significance of the Magna Carta?"
    "Translate 'Where can I find a good restaurant?' into French."
    "Explain the concept of 'inflation' in economics."
    "What is the capital of India?"
    "Write a Python function to sort a list of numbers using bubble sort."
    "Who was the first person to walk on the moon?"
    "Translate 'How are you doing today?' into Japanese."
    "What are the different types of blood cells and their functions?"
    "Describe the basic rules of chess."
    "Compose a short science fiction story."
    "What is the difference between HTTP and HTTPS?"
    "Translate 'This is very interesting' into Italian."
    "Explain the concept of 'cloud computing'."
    "What is the capital of South Africa (mention all three if possible)?"
    "Write a function to calculate the area of a circle."
    "Who wrote 'The Great Gatsby'?"
    "Translate 'Excuse me' into Mandarin Chinese (Pinyin)."
    "What are the main functions of the human brain?"
    "Describe the process of making a cup of tea."
    "Write a short fantasy story."
    "What is the purpose of an operating system?"
    "Translate 'I would like a coffee' into German."
    "Explain the difference between renewable and non-renewable resources."
    "What is the capital of Russia?"
    "Write a Python script to find all prime numbers up to N."
    "Who invented the telephone?"
    "Translate 'What is your favorite color?' into Spanish."
    "What are the different layers of the Earth's atmosphere?"
    "Describe a famous historical event in 5 sentences."
    "Compose a short mystery story."
    "What is a DNS server?"
    "Translate 'Have a great weekend!' into French."
    "Explain the concept of 'entropy'."
    "What is the capital of Egypt?"
    "Write a JavaScript function to implement a basic calculator (add, subtract, multiply, divide)."
    "Who painted 'Starry Night'?"
    "Translate 'I am lost' into Japanese."
    "What are the main components of a healthy diet?"
    "Describe the rules of soccer (football)."
    "Write a short adventure story."
    "What is the difference between IPv4 and IPv6?"
    "Translate 'It's a beautiful day' into Italian."
    "Explain the concept of 'natural language processing'."
    "What is the capital of Argentina?"
    "Write a Python function to check if a string is a palindrome."
    "Who wrote 'Don Quixote'?"
    "Translate 'How old are you?' into Mandarin Chinese (Pinyin)."
    "What are the functions of the kidneys?"
    "Describe how to tie a shoelace."
    "Compose a short comedic sketch."
    "What is a 'smart contract' in blockchain?"
    "Translate 'Good night' into German."
    "Explain the theory of plate tectonics."
    "What is the capital of Mexico?"
    "Write a Python script to convert Celsius to Fahrenheit."
    "Who discovered America (from a European perspective)?"
    "Translate 'I need to go to the airport' into Spanish."
    "What are the different states of matter?"
    "Describe a simple magic trick."
    "Write a short piece of travel writing about a fictional place."
    "What is the role of a router in a network?"
    "Translate 'Congratulations!' into French."
    "Explain the concept of 'artificial general intelligence'."
    "What is the capital of Nigeria?"
    "Write a JavaScript function to generate a random number within a range."
    "Who composed the 'Moonlight Sonata'?"
    "Translate 'Can you speak slower, please?' into Japanese."
    "What are the benefits of regular exercise?"
    "Describe the game of basketball."
    "Compose a short fable with a moral."
    "What is 'phishing' in cybersecurity?"
    "Translate 'I agree' into Italian."
    "Explain the Doppler effect."
    "What is the capital of Saudi Arabia?"
    "Write a Python function to find the median of a list."
    "Who wrote 'War and Peace'?"
    "Translate 'What is this?' into Mandarin Chinese (Pinyin)."
    "What are the main parts of a flower and their functions?"
    "Describe how to make a paper airplane."
    "Write a short drama scene."
    "What is 'machine learning bias'?"
    "Translate 'I'm sorry' into German."
    "Explain the concept of 'dark matter'."
    "What is the capital of Indonesia?"
    "Write a Python script to simulate a dice roll."
    "Who invented the light bulb (commercially viable)?"
    "Translate 'Where is the train station?' into Spanish."
    "What are the different types of clouds?"
    "Describe a simple card game."
    "Compose a short poem about technology."
    "What is a 'denial-of-service' attack?"
    "Translate 'Yes, please' into French."
    "Explain the concept of 'quantum entanglement'."
    "What is the capital of Turkey?"
    "Write a JavaScript function to validate an email address format."
    "Who painted 'The Persistence of Memory'?"
    "Translate 'I am tired' into Japanese."
    "What are the key elements of a good presentation?"
    "Describe the game of tennis."
    "Write a short myth about the stars."
    "What is 'two-factor authentication'?"
    "Translate 'No, thank you' into Italian."
    "Explain the concept of 'string theory' in simple terms."
    "What is the capital of Iran?"
    "Write a Python function to merge two sorted lists."
    "Who wrote 'Moby Dick'?"
    "Translate 'How do I get to...?' into Mandarin Chinese (Pinyin)."
    "What are the functions of the human skeleton?"
    "Describe how to cook a simple omelette."
    "Compose a short monologue for a character."
    "What is 'data encryption'?"
    "Translate 'Cheers!' (as in a toast) into German."
    "Explain the concept of 'black dwarf' stars."
    "What is the capital of Thailand?"
    "Write a Python script to generate a password of a given length."
    "Who was Leonardo da Vinci and what were some of his accomplishments?"
    "Translate 'I have a reservation' into Spanish."
    "What are the different layers of a rainforest?"
    "Describe a simple science experiment for kids."
    "Write a short piece of dialogue for a movie."
    "What is 'SQL injection'?"
    "Translate 'I'm looking for...' into French."
    "Explain the concept of 'Occam's Razor'."
    "What is the capital of Pakistan?"
    "Write a JavaScript function to get the current date and time."
    "Who painted 'Guernica'?"
    "Translate 'It was nice talking to you' into Japanese."
    "What are the benefits of meditation?"
    "Describe the game of volleyball."
    "Compose a short legend about a mythical creature."
    "What is 'ransomware'?"
    "Translate 'Can you recommend a book?' into Italian."
    "Explain the 'observer effect' in quantum mechanics."
    "What is the capital of Iraq?"
    "Write a Python function to calculate the Fibonacci sequence up to N terms."
    "Who wrote 'The Odyssey'?"
    "Translate 'What are your hobbies?' into Mandarin Chinese (Pinyin)."
    "What are the functions of plant roots?"
    "Describe how to change a flat tire on a car."
    "Write a short scene for a play."
    "What is 'social engineering' in cybersecurity?"
)

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
# It's important to deactivate, especially if the script is sourced or has complex signal handling.
# For a simple script that exits, it's good practice.
trap 'echo "Deactivating virtual environment..."; deactivate' EXIT SIGINT SIGTERM

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
