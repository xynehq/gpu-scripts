#!/bin/bash
# Test VLLM Vision API with curl
# Usage: ./test_vision_curl.sh [IMAGE_PATH] [SERVER_URL] [PROMPT]

# Default values
IMAGE_PATH="${1:-../assets/sglang-nvitop-test-script.png}"
SERVER_URL="${2:-http://localhost:3000}"
PROMPT="${3:-Describe what you see in this image in detail.}"

# Check if image exists
if [ ! -f "$IMAGE_PATH" ]; then
    echo "Error: Image not found at $IMAGE_PATH"
    exit 1
fi

# Encode image to base64
echo "Encoding image: $IMAGE_PATH"
BASE64_IMAGE=$(base64 -i "$IMAGE_PATH" | tr -d '\n')

echo "Sending request to: $SERVER_URL/v1/chat/completions"
echo "Prompt: $PROMPT"
echo ""

# Send request
curl -X POST "$SERVER_URL/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "model": "zai-org/GLM-4.5V",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "$PROMPT"
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/png;base64,$BASE64_IMAGE"
          }
        }
      ]
    }
  ],
  "temperature": 0.7,
  "max_tokens": 1024
}
EOF

echo ""
