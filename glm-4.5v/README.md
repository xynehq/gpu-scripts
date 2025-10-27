# GLM-4.5V Testing Suite

Comprehensive testing script for GLM-4.5V model running on VLLM server. This script tests both text-only and vision capabilities of the model.

## Overview

`test_glm45v_vllm.py` is a Python script that performs automated testing of the GLM-4.5V multimodal model. It includes:

- **5 Text Query Tests**: Testing language understanding, reasoning, math, creative writing, and code generation
- **5 Vision Query Tests**: Testing image understanding, OCR, technical analysis, and visual reasoning
- **Server Health Check**: Validates VLLM server availability before testing
- **Performance Metrics**: Tracks response times and success rates

## Requirements

```bash
pip install requests
```

## Usage

### Basic Usage

**Test local server (default: localhost:3000):**
```bash
python3 test_glm45v_vllm.py
```

or with executable permission:
```bash
./test_glm45v_vllm.py
```

### Command-Line Options

**Positional argument:**
- `host` - Server host/IP address (default: localhost)

**Optional arguments:**
- `--port PORT` - Server port number (default: 3000)
- `--url URL` - Full server URL (overrides host and port)
- `--image IMAGE` - Path to test image for vision queries
- `-h, --help` - Show help message

### Examples

**Test local server on custom port:**
```bash
python3 test_glm45v_vllm.py --port 8000
```

**Test remote server:**
```bash
python3 test_glm45v_vllm.py 192.168.1.100 --port 8000
```

**Use full URL:**
```bash
python3 test_glm45v_vllm.py --url http://192.168.1.100:8000
```

**Specify custom test image:**
```bash
python3 test_glm45v_vllm.py --image /path/to/test_image.png
```

**Combined options:**
```bash
python3 test_glm45v_vllm.py 10.0.0.5 --port 5000 --image ../assets/custom_test.png
```

## Test Cases

### Text Query Tests

1. **Simple Question** - Basic factual knowledge test
   - Example: "What is the capital of France?"

2. **Math Problem** - Numerical reasoning and calculation
   - Example: Speed calculation problem

3. **Creative Writing** - Language generation and creativity
   - Example: Haiku composition

4. **Code Generation** - Programming knowledge and syntax
   - Example: Fibonacci sequence implementation

5. **Reasoning** - Logical deduction and explanation
   - Example: Syllogism reasoning

### Vision Query Tests

1. **Image Description** - General scene understanding and description

2. **GPU Information Extraction** - Counting objects and reading metrics
   - Extracts GPU count and utilization levels

3. **Technical Analysis** - Tool identification and log analysis
   - Identifies monitoring tools and running models

4. **Performance Analysis** - Efficiency assessment
   - Analyzes GPU memory and compute utilization

5. **Text Recognition** - OCR capabilities
   - Reads session IDs and text from screenshots

## Default Test Image

By default, the script uses:
```
../assets/sglang-nvitop-test-script.png
```

This image is automatically located relative to the script directory. You can override this with the `--image` flag.

## Output

The script provides detailed output including:

- Server health check status
- Individual test results with prompts and responses
- Response time for each query
- Success/failure status for each test
- Summary statistics:
  - Text query pass rate
  - Vision query pass rate
  - Overall pass rate
  - Average response time

### Example Output

```
================================================================================
GLM-4.5V VLLM Test Suite
================================================================================
Server URL: http://localhost:3000
Image Path: ../assets/sglang-nvitop-test-script.png
================================================================================

Checking server health...
✓ Server is running
Available models: {...}

================================================================================
TEXT QUERY TESTS
================================================================================

================================================================================
Test: Simple Question
================================================================================
Prompt: What is the capital of France?

Response: The capital of France is Paris...
Time taken: 2.34s
Status: ✓ SUCCESS

...

================================================================================
TEST SUMMARY
================================================================================

Text Queries: 5/5 passed
Vision Queries: 5/5 passed
Total: 10/10 passed

Average response time: 3.45s

================================================================================
```

## Server Requirements

The VLLM server must be running and accessible at the specified URL with:

- OpenAI-compatible API endpoints (`/v1/chat/completions`, `/v1/models`)
- Model loaded: `zai-org/GLM-4.5V`
- Vision capabilities enabled

## Troubleshooting

**Server not available:**
- Verify VLLM server is running
- Check host/IP and port are correct
- Ensure firewall allows connections

**Image not found:**
- Verify image path is correct
- Use absolute path or correct relative path
- Check file permissions

**Timeout errors:**
- Increase timeout values in script (default: 60s for text, 120s for vision)
- Check GPU memory and availability
- Verify model is loaded correctly

**Vision queries failing:**
- Ensure model supports vision (GLM-4.5V)
- Verify image encoding (base64)
- Check image format is supported (PNG, JPEG)

## Advanced Usage

### Custom Test Cases

Edit the script to add custom test cases in the `run_tests()` function:

```python
text_tests = [
    {
        "name": "Your Custom Test",
        "prompt": "Your custom prompt here"
    }
]

vision_tests = [
    {
        "name": "Your Vision Test",
        "prompt": "Analyze this image..."
    }
]
```

### API Configuration

Modify the payload in `test_text_query()` or `test_vision_query()` methods to customize:

- `temperature`: Controls randomness (0.0-2.0)
- `max_tokens`: Maximum response length
- `model`: Model identifier (if using different model)

## Integration

This script can be integrated into:

- CI/CD pipelines for model validation
- Automated testing workflows
- Performance benchmarking suites
- Model deployment verification

## License

Part of the gpu-scripts repository.
