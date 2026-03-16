"""
Train and compare at least 5 models for crop disease classification (Healthy, Powdery, Rust).
Includes: Logistic Regression, Custom CNN, MobileNetV2, VGG16, and ResNet50V2.
Run from repo root: python training/train_and_compare_models.py
Dataset expected: dataset/Train/Healthy, dataset/Train/Powdery, dataset/Train/Rust
"""

import os
import sys
import json
import numpy as np
import pandas as pd
from PIL import Image
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    roc_auc_score,
)
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers, regularizers, callbacks, Model
from tensorflow.keras.applications import MobileNetV2, VGG16, ResNet50V2

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
# Dataset: use project's dataset/Train (or set CROPSENSE_DATASET_TRAIN for another path)
_DEFAULT_BASE = os.path.join(os.path.dirname(__file__), "..", "dataset", "Train")
BASE_DIR = os.environ.get("CROPSENSE_DATASET_TRAIN", "").strip() or _DEFAULT_BASE
if not os.path.isdir(BASE_DIR):
    BASE_DIR = _DEFAULT_BASE
IMG_SIZE = (128, 128)
CLASSES = ["Healthy", "Powdery", "Rust"]
NUM_CLASSES = len(CLASSES)
RANDOM_STATE = 42
EPOCHS = 30
BATCH_SIZE = 32
VAL_SPLIT = 0.2   # 20% of (train+val) for validation
TEST_SPLIT = 0.1  # 10% of all data for test
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "outputs")
SAVED_MODELS_DIR = os.path.join(os.path.dirname(__file__), "saved_models")
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(SAVED_MODELS_DIR, exist_ok=True)


# ---------------------------------------------------------------------------
# Data loading (same logic as your notebook)
# ---------------------------------------------------------------------------
def clean_images(folder: str) -> None:
    """Remove corrupted images."""
    for subdir in CLASSES:
        path = os.path.join(folder, subdir)
        if not os.path.isdir(path):
            continue
        for f in os.listdir(path):
            fp = os.path.join(path, f)
            try:
                Image.open(fp).verify()
            except Exception:
                try:
                    os.remove(fp)
                except Exception:
                    pass


def load_dataset(folder: str):
    """Load images and labels. Returns X (N, H, W, 3), y_raw (class names)."""
    X, y_raw = [], []
    for label in CLASSES:
        path = os.path.join(folder, label)
        if not os.path.isdir(path):
            print(f"Warning: {path} not found, skipping.")
            continue
        for f in os.listdir(path):
            fp = os.path.join(path, f)
            try:
                img = Image.open(fp).convert("RGB")
                img = img.resize(IMG_SIZE)
                X.append(np.array(img))
                y_raw.append(label)
            except Exception:
                continue
    if not X:
        raise FileNotFoundError(
            f"No images found under {folder}. Expected subdirs: {CLASSES}"
        )
    X = np.array(X, dtype=np.float32) / 255.0
    return X, np.array(y_raw)


# ---------------------------------------------------------------------------
# Model 1: Logistic Regression
# ---------------------------------------------------------------------------
def train_logistic_regression(X_train, y_train, X_test, y_test):
    n = X_train.shape[0]
    X_flat = X_train.reshape(n, -1)
    scaler = StandardScaler()
    X_flat = scaler.fit_transform(X_flat)
    X_test_flat = scaler.transform(X_test.reshape(X_test.shape[0], -1))

    clf = LogisticRegression(
        penalty="l2",
        C=1.0,
        solver="saga",
        max_iter=1000,
        multi_class="multinomial",
        class_weight="balanced",
        random_state=RANDOM_STATE,
    )
    clf.fit(X_flat, y_train)
    y_pred = clf.predict(X_test_flat)
    return {
        "model": clf,
        "scaler": scaler,
        "type": "sklearn",
        "y_pred": y_pred,
        "y_true": y_test,
    }


# ---------------------------------------------------------------------------
# Model 2: Custom CNN (Adam + L1) - same as your notebook best model
# ---------------------------------------------------------------------------
def build_custom_cnn(input_shape=(128, 128, 3), num_classes=3):
    reg = regularizers.l1(0.001)
    model = keras.Sequential([
        layers.Conv2D(32, 3, activation="relu", padding="same", kernel_regularizer=reg, input_shape=input_shape),
        layers.BatchNormalization(),
        layers.MaxPooling2D(2),
        layers.Conv2D(64, 3, activation="relu", padding="same", kernel_regularizer=reg),
        layers.BatchNormalization(),
        layers.MaxPooling2D(2),
        layers.Conv2D(128, 3, activation="relu", padding="same", kernel_regularizer=reg),
        layers.BatchNormalization(),
        layers.MaxPooling2D(2),
        layers.Flatten(),
        layers.Dense(128, activation="relu"),
        layers.Dense(64, activation="relu"),
        layers.Dropout(0.2),
        layers.Dense(num_classes, activation="softmax"),
    ])
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.0001),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


# ---------------------------------------------------------------------------
# Model 3: MobileNetV2 (transfer learning)
# ---------------------------------------------------------------------------
def build_mobilenetv2(input_shape=(128, 128, 3), num_classes=3):
    base = MobileNetV2(
        input_shape=input_shape,
        include_top=False,
        weights="imagenet",
        pooling="avg",
    )
    base.trainable = False
    x = base.output
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.3)(x)
    out = layers.Dense(num_classes, activation="softmax")(x)
    model = Model(base.input, out)
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


# ---------------------------------------------------------------------------
# Model 4: VGG16 (transfer learning)
# ---------------------------------------------------------------------------
def build_vgg16(input_shape=(128, 128, 3), num_classes=3):
    base = VGG16(
        input_shape=input_shape,
        include_top=False,
        weights="imagenet",
        pooling="avg",
    )
    base.trainable = False
    x = base.output
    x = layers.Dense(256, activation="relu")(x)
    x = layers.Dropout(0.4)(x)
    out = layers.Dense(num_classes, activation="softmax")(x)
    model = Model(base.input, out)
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


# ---------------------------------------------------------------------------
# Model 5: ResNet50V2 (transfer learning)
# ---------------------------------------------------------------------------
def build_resnet50v2(input_shape=(128, 128, 3), num_classes=3):
    base = ResNet50V2(
        input_shape=input_shape,
        include_top=False,
        weights="imagenet",
        pooling="avg",
    )
    base.trainable = False
    x = base.output
    x = layers.Dense(128, activation="relu")(x)
    x = layers.Dropout(0.3)(x)
    out = layers.Dense(num_classes, activation="softmax")(x)
    model = Model(base.input, out)
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )
    return model


# ---------------------------------------------------------------------------
# Evaluation helpers
# ---------------------------------------------------------------------------
def eval_sklearn(result, name):
    y_true, y_pred = result["y_true"], result["y_pred"]
    try:
        roc = roc_auc_score(y_true, result["model"].predict_proba(
            result.get("X_test_flat") or result["X_test_flat_"]
        ), multi_class="ovr", average="weighted")
    except Exception:
        roc = 0.0
    return {
        "model_name": name,
        "accuracy": accuracy_score(y_true, y_pred),
        "precision": precision_score(y_true, y_pred, average="weighted", zero_division=0),
        "recall": recall_score(y_true, y_pred, average="weighted", zero_division=0),
        "f1": f1_score(y_true, y_pred, average="weighted", zero_division=0),
        "roc_auc": roc,
    }


def eval_keras(model, X_test, y_test, name):
    y_pred_proba = model.predict(X_test, verbose=0)
    y_pred = np.argmax(y_pred_proba, axis=1)
    try:
        roc = roc_auc_score(y_test, y_pred_proba, multi_class="ovr", average="weighted")
    except Exception:
        roc = 0.0
    return {
        "model_name": name,
        "accuracy": accuracy_score(y_test, y_pred),
        "precision": precision_score(y_test, y_pred, average="weighted", zero_division=0),
        "recall": recall_score(y_test, y_pred, average="weighted", zero_division=0),
        "f1": f1_score(y_test, y_pred, average="weighted", zero_division=0),
        "roc_auc": roc,
    }


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    print("CropSense: training and comparing 5 models (LR, Custom CNN, MobileNetV2, VGG16, ResNet50V2)")
    print("Dataset base:", os.path.abspath(BASE_DIR))

    if not os.path.isdir(BASE_DIR):
        print("ERROR: Dataset directory not found. Create dataset/Train with subdirs: Healthy, Powdery, Rust")
        sys.exit(1)

    clean_images(BASE_DIR)
    X, Y_raw = load_dataset(BASE_DIR)
    print(f"Loaded {X.shape[0]} images, shape {X.shape}")

    le = LabelEncoder()
    Y = le.fit_transform(Y_raw)

    # Split: 70% train, 20% val, 10% test (of remainder)
    X_train, X_rest, y_train, y_rest = train_test_split(
        X, Y, test_size=0.3, random_state=RANDOM_STATE, stratify=Y
    )
    X_val, X_test, y_val, y_test = train_test_split(
        X_rest, y_rest, test_size=1.0 / 3.0, random_state=RANDOM_STATE, stratify=y_rest
    )
    print(f"Train: {len(X_train)}, Val: {len(X_val)}, Test: {len(X_test)}")

    results = []
    best_model_info = None
    best_accuracy = -1.0

    # ----- 1. Logistic Regression -----
    print("\n--- Training 1/5: Logistic Regression ---")
    lr_result = train_logistic_regression(X_train, y_train, X_test, y_test)
    # For ROC we need test features scaled
    n_test = X_test.shape[0]
    scaler = lr_result["scaler"]
    X_test_flat = scaler.transform(X_test.reshape(n_test, -1))
    lr_result["X_test_flat_"] = X_test_flat
    try:
        roc = roc_auc_score(
            y_test,
            lr_result["model"].predict_proba(X_test_flat),
            multi_class="ovr",
            average="weighted",
        )
    except Exception:
        roc = 0.0
    r1 = {
        "model_name": "Logistic Regression",
        "accuracy": accuracy_score(y_test, lr_result["y_pred"]),
        "precision": precision_score(y_test, lr_result["y_pred"], average="weighted", zero_division=0),
        "recall": recall_score(y_test, lr_result["y_pred"], average="weighted", zero_division=0),
        "f1": f1_score(y_test, lr_result["y_pred"], average="weighted", zero_division=0),
        "roc_auc": roc,
    }
    results.append(r1)
    if r1["accuracy"] > best_accuracy:
        best_accuracy = r1["accuracy"]
        best_model_info = ("lr", lr_result["model"], {"scaler": scaler, "label_encoder": le})

    # ----- 2. Custom CNN -----
    print("\n--- Training 2/5: Custom CNN (Adam + L1) ---")
    cnn = build_custom_cnn(input_shape=(*IMG_SIZE, 3), num_classes=NUM_CLASSES)
    early = callbacks.EarlyStopping(
        monitor="val_accuracy", patience=5, restore_best_weights=True, mode="max"
    )
    cnn.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=[early],
        verbose=1,
    )
    r2 = eval_keras(cnn, X_test, y_test, "Custom CNN (Adam+L1)")
    results.append(r2)
    if r2["accuracy"] > best_accuracy:
        best_accuracy = r2["accuracy"]
        best_model_info = ("custom_cnn", cnn, {"label_encoder": le})

    # ----- 3. MobileNetV2 -----
    print("\n--- Training 3/5: MobileNetV2 ---")
    mobilenet = build_mobilenetv2(input_shape=(*IMG_SIZE, 3), num_classes=NUM_CLASSES)
    early = callbacks.EarlyStopping(
        monitor="val_accuracy", patience=5, restore_best_weights=True, mode="max"
    )
    mobilenet.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=[early],
        verbose=1,
    )
    r3 = eval_keras(mobilenet, X_test, y_test, "MobileNetV2")
    results.append(r3)
    if r3["accuracy"] > best_accuracy:
        best_accuracy = r3["accuracy"]
        best_model_info = ("mobilenetv2", mobilenet, {"label_encoder": le})

    # ----- 4. VGG16 -----
    print("\n--- Training 4/5: VGG16 ---")
    vgg = build_vgg16(input_shape=(*IMG_SIZE, 3), num_classes=NUM_CLASSES)
    early = callbacks.EarlyStopping(
        monitor="val_accuracy", patience=5, restore_best_weights=True, mode="max"
    )
    vgg.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=[early],
        verbose=1,
    )
    r4 = eval_keras(vgg, X_test, y_test, "VGG16")
    results.append(r4)
    if r4["accuracy"] > best_accuracy:
        best_accuracy = r4["accuracy"]
        best_model_info = ("vgg16", vgg, {"label_encoder": le})

    # ----- 5. ResNet50V2 -----
    print("\n--- Training 5/5: ResNet50V2 ---")
    resnet = build_resnet50v2(input_shape=(*IMG_SIZE, 3), num_classes=NUM_CLASSES)
    early = callbacks.EarlyStopping(
        monitor="val_accuracy", patience=5, restore_best_weights=True, mode="max"
    )
    resnet.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=EPOCHS,
        batch_size=BATCH_SIZE,
        callbacks=[early],
        verbose=1,
    )
    r5 = eval_keras(resnet, X_test, y_test, "ResNet50V2")
    results.append(r5)
    if r5["accuracy"] > best_accuracy:
        best_accuracy = r5["accuracy"]
        best_model_info = ("resnet50v2", resnet, {"label_encoder": le})

    # ----- Summary -----
    df = pd.DataFrame(results)
    df = df.sort_values("accuracy", ascending=False).reset_index(drop=True)
    print("\n" + "=" * 60)
    print("MODEL COMPARISON (sorted by accuracy)")
    print("=" * 60)
    print(df.to_string(index=False))
    print("=" * 60)
    print(f"Best model: {df.iloc[0]['model_name']} (accuracy = {df.iloc[0]['accuracy']:.4f})")

    # Save best model and metadata
    if best_model_info:
        name, model_obj, extra = best_model_info
        if name == "lr":
            import joblib
            path = os.path.join(SAVED_MODELS_DIR, "best_model_lr.pkl")
            joblib.dump(
                {"model": model_obj, "scaler": extra["scaler"], "label_encoder": extra["label_encoder"]},
                path,
            )
            print(f"Saved best (LR) to {path}")
        else:
            # Save as best_model.keras so backend can load via CROPSENSE_MODEL_PATH=outputs/best_model.keras
            out_path = os.path.join(OUTPUT_DIR, "best_model.keras")
            model_obj.save(out_path)
            print(f"Saved best ({name}) to {out_path}")
        # Class names for API
        meta_path = os.path.join(OUTPUT_DIR, "model_metadata.json")
        with open(meta_path, "w") as f:
            json.dump({"class_names": CLASSES}, f, indent=2)
        print(f"Saved class names to {meta_path}")

    # Save comparison CSV
    csv_path = os.path.join(SAVED_MODELS_DIR, "model_comparison.csv")
    df.to_csv(csv_path, index=False)
    print(f"Comparison table saved to {csv_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main() or 0)
