from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import tensorflow as tf
from PIL import Image
import numpy as np
import io
import pickle
import os
import json

from services import WeatherService, RwandaAgronomistAdvisor, RwandaCropPlanner

# Try to import huggingface_hub (optional dependency)
try:
    from huggingface_hub import hf_hub_download
    HF_AVAILABLE = True
except ImportError:
    HF_AVAILABLE = False
    print("⚠ huggingface_hub not installed. Install with: pip install huggingface_hub")

# --- Initialization ---
app = FastAPI(title="CropSense AI API", version="1.0.0")

# Allow your Flutter and React apps to communicate with this server
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load your exported Keras model and class labels
model = None
label_encoder = None  # Optional: from sklearn
CLASS_NAMES: list[str] = []  # Fallback: from model_metadata.json

def load_model():
    """
    Load model from Hugging Face (if configured) or fallback to local file.
    Priority: HUGGINGFACE_MODEL_ID > CROPSENSE_MODEL_PATH > default local path
    """
    global model
    model = None
    
    # Option 1: Try loading from Hugging Face
    hf_model_id = os.environ.get("HUGGINGFACE_MODEL_ID")
    if hf_model_id and HF_AVAILABLE:
        try:
            print(f"🔄 Attempting to load model from Hugging Face: {hf_model_id}")
            # Try best_model.keras first (from training script), then legacy name
            for fname in ("best_model.keras", "best_MobileNetV2.keras"):
                try:
                    model_file = hf_hub_download(
                        repo_id=hf_model_id,
                        filename=fname,
                        cache_dir=".hf_cache"
                    )
                    break
                except Exception:
                    continue
            else:
                raise FileNotFoundError("No best_model.keras or best_MobileNetV2.keras in repo")
            model = tf.keras.models.load_model(model_file)
            print(f"✓ Model loaded successfully from Hugging Face: {hf_model_id}")
            return
        except Exception as e:
            print(f"✗ Error loading model from Hugging Face: {e}")
            print("   Falling back to local model...")
    
    # Option 2: Load from local file (fallback)
    try:
        default_path = (
            "outputs/best_model.keras"
            if os.path.exists("outputs/best_model.keras")
            else "outputs/best_MobileNetV2.keras"
        )
        model_path = os.environ.get("CROPSENSE_MODEL_PATH", default_path)
        if os.path.exists(model_path):
            model = tf.keras.models.load_model(model_path)
            print(f"✓ Model loaded successfully from local path: {model_path}")
        else:
            print(f"✗ Model file not found: {model_path}")
            model = None
    except Exception as e:
        print(f"✗ Error loading local model: {e}")
        model = None

def load_label_encoder():
    """
    Try to load a sklearn LabelEncoder from pickle.
    If not available, fall back to loading class names from model_metadata.json.
    """
    global label_encoder, CLASS_NAMES

    # First, try the pickle file (if you exported it)
    try:
        with open("outputs/label_encoder.pkl", "rb") as f:
            label_encoder = pickle.load(f)
        # If the encoder has classes_, also cache them for reference
        if hasattr(label_encoder, "classes_"):
            CLASS_NAMES = [str(c) for c in label_encoder.classes_]
        print("✓ Label encoder loaded successfully from outputs/label_encoder.pkl")
        return
    except Exception as e:
        print(f"✗ Error loading label encoder from pickle: {e}")
        label_encoder = None

    # Fallback: load class names from model_metadata.json
    # Try Hugging Face first, then local file
    hf_model_id = os.environ.get("HUGGINGFACE_MODEL_ID")
    if hf_model_id and HF_AVAILABLE:
        try:
            meta_file = hf_hub_download(
                repo_id=hf_model_id,
                filename="model_metadata.json",
                cache_dir=".hf_cache"
            )
            with open(meta_file, "r") as f:
                meta = json.load(f)
            classes = meta.get("classes") or meta.get("class_names") or []
            CLASS_NAMES = [str(c) for c in classes]
            if CLASS_NAMES:
                print(f"✓ Loaded class names from Hugging Face: {CLASS_NAMES}")
                return
        except Exception as e:
            print(f"✗ Error loading metadata from Hugging Face: {e}")
    
    # Fallback to local file
    try:
        meta_path = os.path.join("outputs", "model_metadata.json")
        with open(meta_path, "r") as f:
            meta = json.load(f)
        classes = meta.get("classes") or meta.get("class_names") or []
        CLASS_NAMES = [str(c) for c in classes]
        if CLASS_NAMES:
            print(f"✓ Loaded class names from {meta_path}: {CLASS_NAMES}")
        else:
            print(f"✗ No 'classes' or 'class_names' in {meta_path}")
    except Exception as e:
        print(f"✗ Error loading class names from model_metadata.json: {e}")
        CLASS_NAMES = []

# Load model and encoder on startup
load_model()
load_label_encoder()

# Initialize services
weather_service = WeatherService()
advisor = RwandaAgronomistAdvisor()
crop_planner = RwandaCropPlanner()

# --- Health Check Endpoint ---
@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "status": "CropSense AI API is running",
        "version": "1.0.0",
        "model_loaded": model is not None,
        "encoder_loaded": label_encoder is not None
    }

@app.get("/health")
async def health():
    """Detailed health check"""
    return {
        "status": "healthy",
        "model": "loaded" if model is not None else "not loaded",
        "label_encoder": "loaded" if label_encoder is not None else "not loaded",
        "weather_service": "available",
        "advisor_service": "available",
        "crop_planner_rows": len(crop_planner._rows),
    }

# --- Prediction Endpoint ---
@app.post("/predict")
async def predict(file: UploadFile = File(...)):
    """
    Predict crop disease from image and provide advice
    
    - **file**: Image file of the crop leaf or plant
    - Returns: Prediction, weather data, and agronomic advice
    """
    # If the ML model or class mapping is missing, return a graceful demo response
    if model is None or (label_encoder is None and not CLASS_NAMES):
        weather = weather_service.get_weather_data("Rwanda")
        fallback_crop = "maize"
        used_weather_fallback = False
        try:
            t = weather.get("temperature", 20)
            h = weather.get("humidity", 60)
            if t in (None, "N/A"):
                temp_val = 20.0
                used_weather_fallback = True
            else:
                temp_val = float(t)
            if h in (None, "N/A"):
                hum_val = 60.0
                used_weather_fallback = True
            else:
                hum_val = float(h)
        except (TypeError, ValueError):
            temp_val, hum_val = 20.0, 60.0
            used_weather_fallback = True
        advice = advisor.get_advice(
            crop=fallback_crop,
            temperature=temp_val,
            humidity=hum_val,
        )

        return {
            "prediction": "Model not loaded - showing example advice for maize",
            "confidence": 0.0,
            "weather": weather,
            "advice": advice,
            "weather_is_realtime": not used_weather_fallback,
            "weather_note": "Real-time weather unavailable; showing generic advice based on typical conditions."
            if used_weather_fallback
            else "Advice uses real-time weather from Open-Meteo.",
            "timestamp": weather.get("timestamp"),
        }
    
    try:
        # Read and preprocess the image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        
        # Resize to match model input (trained with IMG_SIZE=128 in notebook)
        image = image.resize((128, 128))
        image_array = np.array(image) / 255.0
        image_array = np.expand_dims(image_array, axis=0)
        
        # Make prediction
        predictions = model.predict(image_array)
        predicted_class_idx = np.argmax(predictions[0])
        confidence = float(predictions[0][predicted_class_idx])
        
        # Decode prediction: prefer LabelEncoder if available, otherwise CLASS_NAMES
        if label_encoder is not None:
            predicted_crop = label_encoder.inverse_transform([predicted_class_idx])[0]
        elif CLASS_NAMES and 0 <= predicted_class_idx < len(CLASS_NAMES):
            predicted_crop = CLASS_NAMES[predicted_class_idx]
        else:
            predicted_crop = f"class_{predicted_class_idx}"
        
        # Fetch weather data
        weather = weather_service.get_weather_data("Rwanda")
        # Coerce to float so advisor never gets str (e.g. "N/A")
        used_weather_fallback = False
        try:
            t = weather.get("temperature", 20)
            if t in (None, "N/A"):
                temp_val = 20.0
                used_weather_fallback = True
            else:
                temp_val = float(t)
        except (TypeError, ValueError):
            temp_val = 20.0
            used_weather_fallback = True
        try:
            h = weather.get("humidity", 60)
            if h in (None, "N/A"):
                hum_val = 60.0
                used_weather_fallback = True
            else:
                hum_val = float(h)
        except (TypeError, ValueError):
            hum_val = 60.0
            used_weather_fallback = True

        # Get agronomic advice
        advice = advisor.get_advice(
            crop=predicted_crop,
            temperature=temp_val,
            humidity=hum_val,
        )
        
        return {
            "prediction": predicted_crop,
            "confidence": round(confidence * 100, 2),
            "weather": weather,
            "advice": advice,
             "weather_is_realtime": not used_weather_fallback,
             "weather_note": "Real-time weather unavailable; showing generic advice based on typical conditions."
             if used_weather_fallback
             else "Advice uses real-time weather from Open-Meteo.",
            "timestamp": weather.get("timestamp"),
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

# --- Weather Endpoint ---
@app.get("/weather")
async def get_weather(location: str = "Rwanda", province: str = "", district: str = ""):
    """Get current weather data for a location (pass province/district for accurate coords)"""
    try:
        display = (f"{district}, {province}".strip(", ") if (district or province) else None) or location or "Rwanda"
        weather = weather_service.get_weather_data(display, province=province, district=district)
        return weather
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Weather error: {str(e)}")

# --- Advice Endpoint ---
@app.post("/advice")
async def get_advice(crop: str, temperature: float = 20, humidity: float = 60):
    """Get agronomic advice for a specific crop"""
    try:
        advice = advisor.get_advice(crop, temperature, humidity)
        return advice
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Advice error: {str(e)}")

# --- Crops List Endpoint ---
@app.get("/crops")
async def get_crops_list():
    """Get list of supported crops"""
    crops = list(advisor.crop_advice.keys())
    return {
        "supported_crops": crops,
        "total": len(crops)
    }

# --- AI Advisor / Season Planning Endpoint ---
@app.post("/advisor")
async def ai_advisor(payload: dict):
    """
    Recommend crops based on province, district, land type and season using the
    Rwanda crop calendar data.

    Expected payload:
    {
      "province": "...",
      "district": "...",
      "sector": "...",
      "cell": "...",
      "village": "...",
      "season": "season-a" | "season-b",
      "landType": "wetland" | "hillside" | "valley" | "plateau"
    }
    """
    if not crop_planner._rows:
        raise HTTPException(
            status_code=500,
            detail="Crop calendar data not available on server",
        )

    province = (payload.get("province") or "").strip()
    district = (payload.get("district") or "").strip()
    season = (payload.get("season") or "").strip()
    land_type = (payload.get("landType") or "").strip()

    # Get location-specific weather data
    location_name = f"{district}, {province}" if district and province else province or "Rwanda"
    weather = weather_service.get_weather_data(
        location=location_name,
        province=province,
        district=district
    )

    # Get crop recommendations with weather consideration
    recs = crop_planner.get_recommendations(
        province=province,
        district=district,
        land_type=land_type,
        season=season,
        weather_data=weather,
    )

    if not recs:
        return {
            "input": {
                "province": province,
                "district": district,
                "season": season,
                "landType": land_type,
            },
            "best_match": None,
            "alternatives": [],
            "message": "No matching crops found for this combination. Try a different land type or season.",
        }

    # First result as best match, rest as alternatives
    best = recs[0]
    alts = recs[1:4]  # limit to 3 alternatives for UI

    # Get weather-based advice for each crop
    def to_dict(r):
        # Get specific advice for this crop based on current weather
        temp = weather.get("temperature")
        humidity = weather.get("humidity")
        
        advice = None
        if temp != "N/A" and humidity != "N/A":
            try:
                temp_float = float(temp) if isinstance(temp, (int, float, str)) and temp != "N/A" else 20
                humidity_float = float(humidity) if isinstance(humidity, (int, float, str)) and humidity != "N/A" else 60
                advice = advisor.get_advice(
                    crop=r.crop,
                    temperature=temp_float,
                    humidity=humidity_float
                )
            except (ValueError, TypeError):
                pass
        
        return {
            "crop": r.crop,
            "agroZone": r.agro_zone,
            "reason": r.reason,
            "sowingWindow": r.sowing_window,
            "growingPeriod": r.growing_period,
            "weatherAdvice": advice,
        }

    return {
        "input": {
            "province": province,
            "district": district,
            "season": season,
            "landType": land_type,
        },
        "weather": weather,
        "best_match": to_dict(best),
        "alternatives": [to_dict(r) for r in alts],
    }

# --- Error Handling ---
@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"detail": exc.detail}
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)