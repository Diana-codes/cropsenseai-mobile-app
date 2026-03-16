# CropSense – Model training and comparison

This folder contains:

- **`CropSense_Model_Training.ipynb`** – Jupyter notebook to train and compare 5 models (run from repo root or from this folder).
- **`train_and_compare_models.py`** – Same workflow as a script.

Both train **5 models** on the same crop-disease dataset and picks the one with the **highest accuracy**:

| # | Model | Type |
|---|--------|------|
| 1 | **Logistic Regression** | Classical ML (flattened 128×128 images) |
| 2 | **Custom CNN** | Your notebook-style CNN (Adam + L1) |
| 3 | **MobileNetV2** | Transfer learning (ImageNet, frozen base) |
| 4 | **VGG16** | Transfer learning (ImageNet, frozen base) |
| 5 | **ResNet50V2** | Transfer learning (ImageNet, frozen base) |

Classes: **Healthy**, **Powdery**, **Rust**.

## Dataset

Images live in this repo under:

```
dataset/
  Train/
    Healthy/   <- leaf images (no disease)
    Powdery/   <- powdery mildew
    Rust/      <- rust
```

- Format: JPG/PNG, any resolution (resized to **128×128**).
- To use a different path, set env: `CROPSENSE_DATASET_TRAIN=/path/to/dataset/Train`.

## Run training

From the **repo root**:

```bash
# Optional: use a venv
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate

# Install backend + training deps
pip install -r requirements.txt
pip install -r training/requirements-training.txt

# Train and compare all 5 models
python training/train_and_compare_models.py
```

Outputs:

- **Console**: table of accuracy, precision, recall, F1, ROC AUC per model.
- **Best model**:  
  - If best is Keras (CNN / MobileNetV2 / VGG16 / ResNet50V2): saved as `outputs/best_model.keras`.  
  - If best is Logistic Regression: saved as `training/saved_models/best_model_lr.pkl`.
- **Metadata**: `outputs/model_metadata.json` (class names).
- **Comparison**: `training/saved_models/model_comparison.csv`.

## Using the best model in the app

- If the best model is one of the Keras models, point the backend to it:
  - Set `CROPSENSE_MODEL_PATH=outputs/best_model.keras` (or leave default after running the script).
- The API in `main.py` expects a Keras model; if you want to serve the Logistic Regression best model, the backend would need a small branch to load the `.pkl` and run the same preprocessing (128×128, flatten, scale with the saved `StandardScaler`).
