# Upload CropSense model to Hugging Face

So Render (or any server) can load your best model without storing it in the repo.

## 1. Create a repo on Hugging Face

1. Go to [huggingface.co](https://huggingface.co) and sign in.
2. Click **Create new model** (or **New** → **Model**).
3. Name it (e.g. `cropsense-mobilenetv2` or `your-username/cropsense-best-model`).
4. Choose **Public** (or Private if you prefer; then you’ll need a token with read access for Render).
5. Create the repo.

## 2. Upload the two files

Upload these from your CropSense project:

| File on your machine | Upload as (filename in repo) |
|----------------------|-----------------------------|
| `outputs/best_model.keras` | **best_model.keras** |
| `outputs/model_metadata.json` | **model_metadata.json** |

**Option A – Web UI**

1. Open your model repo on Hugging Face.
2. Click **Add file** → **Upload files**.
3. Drag and drop `outputs/best_model.keras` and `outputs/model_metadata.json` from your project (or choose them).
4. Commit (e.g. “Add CropSense best model and metadata”).

**Option B – CLI (from repo root)**

Activate your venv so the `hf` command is available, then login and upload:

```bash
cd ~/Documents/cropsenseai-mobile-app
source .venv/bin/activate
hf auth login
hf upload Ruzindana/cropsense-mobilenetv2 outputs/best_model.keras best_model.keras
hf upload Ruzindana/cropsense-mobilenetv2 outputs/model_metadata.json model_metadata.json
```

If you don’t use the venv, use the full path to `hf`: `.venv/bin/hf` instead of `hf`.

## 3. Set env vars on Render

In your Render service → **Environment**:

- **HUGGINGFACE_MODEL_ID** = `YOUR_USERNAME/YOUR_REPO_NAME` (e.g. `Diana-codes/cropsense-mobilenetv2`)
- **HUGGINGFACE_HUB_TOKEN** = a Hugging Face token with **read** access (create at [huggingface.co/settings/tokens](https://huggingface.co/settings/tokens))

Redeploy. On startup the API will download `best_model.keras` and `model_metadata.json` from this repo and use them for predictions.
