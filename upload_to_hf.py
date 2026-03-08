#!/usr/bin/env python3
"""
Helper script to upload model files to Hugging Face.
Usage:
    python upload_to_hf.py your-username/cropsense-mobilenetv2
"""

import sys
import os
from pathlib import Path

try:
    from huggingface_hub import HfApi, login
except ImportError:
    print("❌ huggingface_hub not installed. Install with: pip install huggingface_hub")
    sys.exit(1)

def upload_model(repo_id: str):
    """Upload model and metadata to Hugging Face"""
    
    api = HfApi()
    
    # Check if logged in
    try:
        api.whoami()
    except Exception:
        print("🔐 Please login to Hugging Face first:")
        print("   Run: huggingface-cli login")
        print("   Or: python -c 'from huggingface_hub import login; login()'")
        sys.exit(1)
    
    # Files to upload
    files_to_upload = {
        "outputs/best_MobileNetV2.keras": "best_MobileNetV2.keras",
        "outputs/model_metadata.json": "model_metadata.json",
    }
    
    # Check files exist
    missing_files = []
    for local_path, _ in files_to_upload.items():
        if not os.path.exists(local_path):
            missing_files.append(local_path)
    
    if missing_files:
        print(f"❌ Missing files:")
        for f in missing_files:
            print(f"   - {f}")
        sys.exit(1)
    
    print(f"📤 Uploading to {repo_id}...")
    
    # Upload files
    for local_path, remote_path in files_to_upload.items():
        print(f"   Uploading {local_path} -> {remote_path}")
        try:
            api.upload_file(
                path_or_fileobj=local_path,
                path_in_repo=remote_path,
                repo_id=repo_id,
                repo_type="model"
            )
            print(f"   ✓ {remote_path} uploaded successfully")
        except Exception as e:
            print(f"   ✗ Error uploading {remote_path}: {e}")
            sys.exit(1)
    
    print(f"\n✅ Model uploaded successfully!")
    print(f"   View at: https://huggingface.co/{repo_id}")
    print(f"\n💡 Set environment variable:")
    print(f"   export HUGGINGFACE_MODEL_ID=\"{repo_id}\"")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python upload_to_hf.py <repo-id>")
        print("Example: python upload_to_hf.py your-username/cropsense-mobilenetv2")
        sys.exit(1)
    
    repo_id = sys.argv[1]
    upload_model(repo_id)
