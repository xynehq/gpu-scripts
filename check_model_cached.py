import sys
import argparse
from huggingface_hub import try_to_load_from_cache
from huggingface_hub.utils import HfHubLogging

# Suppress "HF Token has not been saved" warning if user is not logged in,
# as it's not relevant for just checking the cache.
HfHubLogging.disable_progress_bars()
HfHubLogging.disable_default_handler()


def is_model_cached(repo_id: str, filename_to_check: str = "config.json") -> bool:
    """
    Checks if a specific file for a given Hugging Face repo_id is present in the local cache.
    """
    cached_path = try_to_load_from_cache(repo_id=repo_id, filename=filename_to_check)
    return cached_path is not None

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Check if a Hugging Face model is cached locally.")
    parser.add_argument("repo_id", type=str, help="The Hugging Face repository ID (e.g., 'meta-llama/Llama-2-7b-hf').")
    
    if len(sys.argv) == 1: # No arguments provided
        parser.print_help(sys.stderr)
        sys.exit(2) # Standard exit code for command line syntax errors

    args = parser.parse_args()

    if is_model_cached(args.repo_id):
        # Optional: print(f"Model '{args.repo_id}' (specifically {FILENAME_TO_CHECK}) is cached.")
        sys.exit(0)  # Success, model is cached
    else:
        # Optional: print(f"Model '{args.repo_id}' (specifically {FILENAME_TO_CHECK}) is NOT cached.")
        sys.exit(1)  # Failure, model is not cached
