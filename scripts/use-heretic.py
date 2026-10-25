#!/usr/bin/env python3
"""
Script to use Heretic for removing censorship/barriers from models
after project building.

Usage: python3 scripts/use-heretic.py <model-id>
"""

import subprocess
import sys
import os

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 use-heretic.py <model-id>")
        print("Example: python3 use-heretic.py google/gemma-3-12b-it")
        sys.exit(1)
    
    model_id = sys.argv[1]
    print(f"Starting Heretic decensoring for model: {model_id}")
    print("This may take 20-30 minutes depending on the model and hardware.")
    
    # Run heretic command
    try:
        result = subprocess.run(
            ["heretic", model_id],
            capture_output=True,
            text=True,
            timeout=7200  # 2 hour timeout
        )
        
        print("STDOUT:")
        print(result.stdout)
        
        if result.stderr:
            print("STDERR:")
            print(result.stderr)
        
        if result.returncode == 0:
            print("Heretic decensoring completed successfully!")
        else:
            print(f"Heretic exited with code: {result.returncode}")
            
    except FileNotFoundError:
        print("Error: 'heretic' command not found.")
        print("Please install heretic-llm: pip install heretic-llm")
        sys.exit(1)
    except subprocess.TimeoutExpired:
        print("Error: Heretic timed out after 2 hours.")
        print("The process may still be running in the background.")

if __name__ == "__main__":
    main()
