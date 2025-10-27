#!/usr/bin/env python3
"""
Test script for GLM-4.5V model running on VLLM
Tests both text-only and vision queries
"""

import requests
import json
import base64
import time
import argparse
import os
from pathlib import Path
from typing import Dict, List, Optional


class GLM45VTester:
    def __init__(self, base_url: str = "http://localhost:3000"):
        self.base_url = base_url
        self.chat_endpoint = f"{base_url}/v1/chat/completions"

    def encode_image(self, image_path: str) -> str:
        """Encode image to base64 string"""
        with open(image_path, "rb") as image_file:
            return base64.b64encode(image_file.read()).decode('utf-8')

    def test_text_query(self, prompt: str, test_name: str) -> Dict:
        """Test text-only query"""
        print(f"\n{'='*80}")
        print(f"Test: {test_name}")
        print(f"{'='*80}")
        print(f"Prompt: {prompt}")

        payload = {
            "model": "zai-org/GLM-4.5V",
            "messages": [
                {
                    "role": "user",
                    "content": prompt
                }
            ],
            "temperature": 0.7,
            "max_tokens": 512
        }

        start_time = time.time()
        try:
            response = requests.post(
                self.chat_endpoint,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=60
            )
            elapsed_time = time.time() - start_time

            if response.status_code == 200:
                result = response.json()
                content = result['choices'][0]['message']['content']
                print(f"\nResponse: {content}")
                print(f"Time taken: {elapsed_time:.2f}s")
                print(f"Status: ✓ SUCCESS")
                return {"status": "success", "response": content, "time": elapsed_time}
            else:
                print(f"\nError: {response.status_code}")
                print(f"Response: {response.text}")
                print(f"Status: ✗ FAILED")
                return {"status": "failed", "error": response.text}

        except Exception as e:
            print(f"\nException: {str(e)}")
            print(f"Status: ✗ FAILED")
            return {"status": "failed", "error": str(e)}

    def test_vision_query(self, prompt: str, image_path: str, test_name: str) -> Dict:
        """Test vision query with image"""
        print(f"\n{'='*80}")
        print(f"Test: {test_name}")
        print(f"{'='*80}")
        print(f"Prompt: {prompt}")
        print(f"Image: {image_path}")

        # Encode image
        base64_image = self.encode_image(image_path)

        payload = {
            "model": "zai-org/GLM-4.5V",
            "messages": [
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": prompt
                        },
                        {
                            "type": "image_url",
                            "image_url": {
                                "url": f"data:image/png;base64,{base64_image}"
                            }
                        }
                    ]
                }
            ],
            "temperature": 0.7,
            "max_tokens": 1024
        }

        start_time = time.time()
        try:
            response = requests.post(
                self.chat_endpoint,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=120
            )
            elapsed_time = time.time() - start_time

            if response.status_code == 200:
                result = response.json()
                content = result['choices'][0]['message']['content']
                print(f"\nResponse: {content}")
                print(f"Time taken: {elapsed_time:.2f}s")
                print(f"Status: ✓ SUCCESS")
                return {"status": "success", "response": content, "time": elapsed_time}
            else:
                print(f"\nError: {response.status_code}")
                print(f"Response: {response.text}")
                print(f"Status: ✗ FAILED")
                return {"status": "failed", "error": response.text}

        except Exception as e:
            print(f"\nException: {str(e)}")
            print(f"Status: ✗ FAILED")
            return {"status": "failed", "error": str(e)}

    def check_server_health(self) -> bool:
        """Check if VLLM server is running"""
        try:
            # Try models endpoint
            response = requests.get(f"{self.base_url}/v1/models", timeout=5)
            if response.status_code == 200:
                print("✓ Server is running")
                models = response.json()
                print(f"Available models: {models}")
                return True
            else:
                print(f"✗ Server responded with status {response.status_code}")
                return False
        except Exception as e:
            print(f"✗ Cannot connect to server: {str(e)}")
            return False


def run_tests(base_url: str, image_path: str):
    """Run all test cases"""
    print("="*80)
    print("GLM-4.5V VLLM Test Suite")
    print("="*80)
    print(f"Server URL: {base_url}")
    print(f"Image Path: {image_path}")
    print("="*80)

    tester = GLM45VTester(base_url=base_url)

    # Check server health
    print("\nChecking server health...")
    if not tester.check_server_health():
        print("\n⚠ Server is not available. Please start VLLM server first.")
        return

    results = []

    # Text Query Tests
    print("\n" + "="*80)
    print("TEXT QUERY TESTS")
    print("="*80)

    text_tests = [
        {
            "name": "Simple Question",
            "prompt": "What is the capital of France?"
        },
        {
            "name": "Math Problem",
            "prompt": "Solve this problem: If a train travels 120 km in 2 hours, what is its average speed?"
        },
        {
            "name": "Creative Writing",
            "prompt": "Write a haiku about artificial intelligence."
        },
        {
            "name": "Code Generation",
            "prompt": "Write a Python function to calculate the fibonacci sequence."
        },
        {
            "name": "Reasoning",
            "prompt": "If all cats are animals, and some animals are pets, can we conclude that some cats are pets? Explain your reasoning."
        }
    ]

    for test in text_tests:
        result = tester.test_text_query(test["prompt"], test["name"])
        results.append({"type": "text", "name": test["name"], "result": result})
        time.sleep(1)  # Small delay between requests

    # Vision Query Tests
    print("\n" + "="*80)
    print("VISION QUERY TESTS")
    print("="*80)

    # Check if image exists
    if not Path(image_path).exists():
        print(f"\n⚠ Warning: Image not found at {image_path}")
        print("Skipping vision tests...")
    else:
        vision_tests = [
            {
                "name": "Image Description",
                "prompt": "Describe what you see in this image in detail."
            },
            {
                "name": "GPU Information Extraction",
                "prompt": "How many GPUs are shown in this image and what are their utilization levels?"
            },
            {
                "name": "Technical Analysis",
                "prompt": "What tool is being used to monitor the GPUs and what model is being tested according to the logs?"
            },
            {
                "name": "Performance Analysis",
                "prompt": "Based on the image, analyze the GPU memory usage and compute utilization. Are the GPUs being utilized efficiently?"
            },
            {
                "name": "Text Recognition",
                "prompt": "What is the session ID shown at the top of the screen?"
            }
        ]

        for test in vision_tests:
            result = tester.test_vision_query(test["prompt"], image_path, test["name"])
            results.append({"type": "vision", "name": test["name"], "result": result})
            time.sleep(1)  # Small delay between requests

    # Summary
    print("\n" + "="*80)
    print("TEST SUMMARY")
    print("="*80)

    text_success = sum(1 for r in results if r["type"] == "text" and r["result"]["status"] == "success")
    text_total = sum(1 for r in results if r["type"] == "text")
    vision_success = sum(1 for r in results if r["type"] == "vision" and r["result"]["status"] == "success")
    vision_total = sum(1 for r in results if r["type"] == "vision")

    print(f"\nText Queries: {text_success}/{text_total} passed")
    print(f"Vision Queries: {vision_success}/{vision_total} passed")
    print(f"Total: {text_success + vision_success}/{text_total + vision_total} passed")

    # Calculate average response times
    successful_results = [r for r in results if r["result"]["status"] == "success"]
    if successful_results:
        avg_time = sum(r["result"]["time"] for r in successful_results) / len(successful_results)
        print(f"\nAverage response time: {avg_time:.2f}s")

    print("\n" + "="*80)


def parse_args():
    """Parse command line arguments"""
    parser = argparse.ArgumentParser(
        description='Test GLM-4.5V model running on VLLM',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Test local server on default port 3000
  python3 test_glm45v_vllm.py

  # Test local server on port 8000
  python3 test_glm45v_vllm.py --port 8000

  # Test remote server
  python3 test_glm45v_vllm.py --host 192.168.1.100 --port 8000

  # Use full URL
  python3 test_glm45v_vllm.py --url http://192.168.1.100:8000

  # Specify custom image path
  python3 test_glm45v_vllm.py --image /path/to/image.png
        """
    )

    parser.add_argument(
        'host',
        nargs='?',
        default='localhost',
        help='Server host/IP address (default: localhost)'
    )

    parser.add_argument(
        '--port',
        type=int,
        default=3000,
        help='Server port number (default: 3000)'
    )

    parser.add_argument(
        '--url',
        type=str,
        help='Full server URL (overrides host and port). Example: http://192.168.1.100:8000'
    )

    parser.add_argument(
        '--image',
        type=str,
        help='Path to test image for vision queries'
    )

    return parser.parse_args()


if __name__ == "__main__":
    args = parse_args()

    # Determine base URL
    if args.url:
        base_url = args.url
    else:
        # Construct URL from host and port
        host = args.host
        # Add http:// if not present
        if not host.startswith('http://') and not host.startswith('https://'):
            host = f'http://{host}'
        base_url = f"{host}:{args.port}"

    # Determine image path
    if args.image:
        image_path = args.image
    else:
        # Default to script directory + assets/sglang-nvitop-test-script.png
        script_dir = os.path.dirname(os.path.abspath(__file__))
        image_path = os.path.join(script_dir, "assets", "sglang-nvitop-test-script.png")

    run_tests(base_url, image_path)
