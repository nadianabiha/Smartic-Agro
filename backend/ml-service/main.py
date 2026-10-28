from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field
from typing import Optional
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
import joblib
import numpy as np
import pandas as pd
import os
import warnings

warnings.filterwarnings("ignore")

app = FastAPI(title="SmartICAgro ML Service")

# ======================================================
# GLOBAL VARIABLES FOR MODEL
# ======================================================
model = None
scaler = None
labels = None
feature_columns = ["N", "P", "K", "temperature", "humidity", "pH"]
altitude_df = None

# ======================================================
# STARTUP EVENT TO LOAD MODEL ONCE
# ======================================================
@app.on_event("startup")
async def startup_event():
    global model, scaler, labels, altitude_df, feature_columns
    
    BASE_DIR = os.path.dirname(__file__)
    MODEL_PATH = os.path.join(BASE_DIR, "models", "crop_model_bundle.joblib")
    ALTITUDE_RULE_PATH = os.path.join(BASE_DIR, "data", "crop_altitude_rules.csv")
    
    print(f"[STARTUP] Loading ML model from {MODEL_PATH}")
    try:
        model_bundle = joblib.load(MODEL_PATH)
        model = model_bundle["model"]
        scaler = model_bundle["scaler"]
        labels = model_bundle["labels"]
        feature_columns = model_bundle.get("feature_columns", ["N", "P", "K", "temperature", "humidity", "pH"])
        print("[STARTUP] Model loaded successfully")
    except Exception as e:
        print(f"[ERROR] Model load failed: {str(e)}")
        # In a real microservice, you might want to raise an exception here
        # so the container fails to start, but we'll let it run and fail on prediction.
        
    print(f"[STARTUP] Loading altitude rules from {ALTITUDE_RULE_PATH}")
    try:
        altitude_df = pd.read_csv(ALTITUDE_RULE_PATH)
        altitude_df["crop"] = altitude_df["crop"].str.lower()
        print("[STARTUP] Altitude rules loaded successfully")
    except Exception as e:
        print(f"[ERROR] Altitude rule load failed: {str(e)}")


# ======================================================
# SCHEMAS
# ======================================================
class PredictRequest(BaseModel):
    N: float
    P: float
    K: float
    temperature: float
    humidity: float
    pH: Optional[float] = None
    ph: Optional[float] = None
    altitude: Optional[float] = 0.0
    ec: Optional[float] = None

# ======================================================
# HELPER FUNCTIONS
# ======================================================
def filter_by_altitude(top_crops, altitude):
    if altitude_df is None:
        return top_crops
        
    filtered = []
    for item in top_crops:
        crop_name = item["crop"].lower()
        rule = altitude_df[altitude_df["crop"] == crop_name]
        
        if rule.empty:
            continue
            
        min_alt = rule.iloc[0]["min_altitude"]
        max_alt = rule.iloc[0]["max_altitude"]
        
        if min_alt <= altitude <= max_alt:
            filtered.append(item)
            
    return filtered

# ======================================================
# ROUTES
# ======================================================
@app.get("/health")
def health_check():
    return {"status": "healthy", "model_loaded": model is not None}

@app.post("/predict")
async def predict_crop(data: PredictRequest):
    if model is None or scaler is None:
        raise HTTPException(status_code=503, detail="ML model is not loaded or unavailable")
        
    try:
        # Handle case-insensitivity for pH
        ph_val = data.pH if data.pH is not None else data.ph
        if ph_val is None:
            ph_val = 0.0
            
        input_values = {
            "N": data.N, "P": data.P, "K": data.K,
            "temperature": data.temperature, "humidity": data.humidity,
            "pH": ph_val, "ec": data.ec
        }
        missing = [column for column in feature_columns if input_values.get(column) is None]
        if missing:
            raise HTTPException(status_code=422, detail=f"Parameter wajib untuk model ini: {', '.join(missing)}")
        features = np.array([[input_values[column] for column in feature_columns]], dtype=float)

        features_scaled = scaler.transform(features)
        
        proba = model.predict_proba(features_scaled)[0]

        # If altitude > 0, check more candidates for filtering
        num_candidates = 15 if data.altitude > 0 else 5
        top_indices = np.argsort(proba)[::-1][:num_candidates]
        
        top_crops = [
            {
                "crop": labels[idx],
                "probability": round(float(proba[idx]) * 100, 2)
            }
            for idx in top_indices
        ]

        if data.altitude > 0:
            altitude_filtered = filter_by_altitude(top_crops, data.altitude)
            final_crops = altitude_filtered[:5] if altitude_filtered else top_crops[:5]
        else:
            final_crops = top_crops[:5]

        return {
            "status": "success",
            "data": {
                "altitude": data.altitude,
                "prediction": final_crops[0]["crop"] if final_crops else None,
                "confidence": final_crops[0]["probability"] if final_crops else 0,
                "top_crops": final_crops
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
