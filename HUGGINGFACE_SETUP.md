# Hugging Face Model Deployment Guide

## Why Hugging Face?

✅ **No Git Bloat**: Models stored in the cloud, not in your repository  
✅ **Free Hosting**: Unlimited storage for public models  
✅ **Easy Versioning**: Track model versions like code  
✅ **Production Ready**: Fast CDN, reliable access  
✅ **Easy Updates**: Update models without redeploying code  

## Quick Start

### Step 1: Install Dependencies

```bash
pip install huggingface_hub
```

### Step 2: Get Your Hugging Face Token

1. Go to https://huggingface.co/settings/tokens
2. Create a new token (read + write permissions)
3. Copy the token

### Step 3: Login

```bash
huggingface-cli login
# Paste your token when prompted
```

Or programmatically:
```python
from huggingface_hub import login
login()  # Will prompt for token
```

### Step 4: Create Model Repository

1. Go to https://huggingface.co/new
2. Create a new model repository (e.g., `your-username/cropsense-mobilenetv2`)
3. Choose **"Model"** as the type
4. Set visibility (Public or Private)

### Step 5: Upload Your Model

**Option A: Using the helper script (Recommended)**
```bash
python upload_to_hf.py your-username/cropsense-mobilenetv2
```

**Option B: Using Hugging Face CLI**
```bash
# Upload the model
huggingface-cli upload your-username/cropsense-mobilenetv2 \
    outputs/best_MobileNetV2.keras \
    best_MobileNetV2.keras

# Upload the metadata file
huggingface-cli upload your-username/cropsense-mobilenetv2 \
    outputs/model_metadata.json \
    model_metadata.json
```

### Step 6: Configure Your Backend

Set the environment variable before running your backend:

```bash
export HUGGINGFACE_MODEL_ID="your-username/cropsense-mobilenetv2"
python main.py
```

Or create a `.env` file:
```
HUGGINGFACE_MODEL_ID=your-username/cropsense-mobilenetv2
```

### Step 7: Verify It Works

When you start your backend, you should see:
```
🔄 Attempting to load model from Hugging Face: your-username/cropsense-mobilenetv2
✓ Model loaded successfully from Hugging Face: your-username/cropsense-mobilenetv2
✓ Loaded class names from Hugging Face: ['Healthy', 'Powdery', 'Rust']
```

## Fallback Behavior

The code automatically falls back to local files if:
- `HUGGINGFACE_MODEL_ID` is not set
- Hugging Face is unavailable
- Model not found on Hugging Face

This ensures your app works in both development and production!

## Updating Models

To update your model:
1. Train/export new model to `outputs/best_MobileNetV2.keras`
2. Run: `python upload_to_hf.py your-username/cropsense-mobilenetv2`
3. The backend will automatically use the latest version

## Production Deployment

For production, set the environment variable in your deployment:
- **Heroku**: `heroku config:set HUGGINGFACE_MODEL_ID=your-username/cropsense-mobilenetv2`
- **Docker**: Add to `docker-compose.yml` or Dockerfile
- **Cloud**: Set in your cloud provider's environment variables

## Troubleshooting

**"huggingface_hub not installed"**
```bash
pip install huggingface_hub
```

**"Authentication required"**
```bash
huggingface-cli login
```

**"Model not found"**
- Check the repo ID is correct
- Ensure the model file is named `best_MobileNetV2.keras` in the repo
- Verify the repository is public or you have access

**"Falling back to local model"**
- This is normal if `HUGGINGFACE_MODEL_ID` is not set
- Check your environment variables
