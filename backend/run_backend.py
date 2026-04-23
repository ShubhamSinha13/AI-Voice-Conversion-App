#!/usr/bin/env python
"""
Simple script to run the FastAPI backend with proper Python path setup
"""
import os
import sys
import subprocess

# Add backend directory to Python path
backend_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, backend_dir)

if __name__ == "__main__":
    # Run uvicorn
    subprocess.run([
        sys.executable, "-m", "uvicorn",
        "app.main:app",
        "--host", "0.0.0.0",
        "--port", "8001",
        "--reload"
    ], cwd=backend_dir)
