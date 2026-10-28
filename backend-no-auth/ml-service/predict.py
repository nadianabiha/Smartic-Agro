from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
import joblib
import numpy as np
import pandas as pd
import json
import sys
import os
import warnings

warnings.filterwarnings("ignore")

# ======================================================
# LOAD MODEL
# ======================================================
BASE_DIR = os.path.dirname(__file__)

MODEL_PATH = os.path.join(BASE_DIR, "models", "crop_model_bundle.joblib")
ALTITUDE_RULE_PATH = os.path.join(BASE_DIR, "data", "crop_altitude_rules.csv")

try:
    model_bundle = joblib.load(MODEL_PATH)

    model = model_bundle["model"]
    scaler = model_bundle["scaler"]
    labels = model_bundle["labels"]

except Exception as e:
    print(json.dumps({
        "status": "error",
        "message": f"Model load failed: {str(e)}"
    }))
    sys.exit(1)


# ======================================================
# LOAD ALTITUDE RULE DATA
# ======================================================
try:
    altitude_df = pd.read_csv(ALTITUDE_RULE_PATH)

    # Normalize crop names for safe matching
    altitude_df["crop"] = altitude_df["crop"].str.lower()

except Exception as e:
    print(json.dumps({
        "status": "error",
        "message": f"Altitude rule load failed: {str(e)}"
    }))
    sys.exit(1)


# ======================================================
# ALTITUDE FILTER FUNCTION
# ======================================================
def filter_by_altitude(top_crops, altitude):
    """
    Filter ML results based on altitude suitability
    Tetap mempertahankan urutan berdasarkan probabilitas tertinggi
    """
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

    # Urutkan kembali berdasarkan probabilitas (dari tertinggi ke terendah)
    filtered.sort(key=lambda x: x["probability"], reverse=True)
    
    return filtered


# ======================================================
# PREDICTION FUNCTION
# ======================================================
def predict_crop(data):
    try:
        # -------------------------------
        # INPUT FEATURES (ML)
        # -------------------------------
        features = np.array([[
            float(data["N"]),
            float(data["P"]),
            float(data["K"]),
            float(data["temperature"]),
            float(data["humidity"]),
            float(data.get("pH") or data.get("ph"))
        ]])

        altitude = float(data.get("altitude", 0))

        features_scaled = scaler.transform(features)

        # -------------------------------
        # ML PREDICTION
        # -------------------------------
        proba = model.predict_proba(features_scaled)[0]

        top_indices = np.argsort(proba)[::-1][:5]
        top_crops = [
            {
                "crop": labels[idx],
                "probability": round(float(proba[idx]) * 100, 2)
            }
            for idx in top_indices
        ]

        # -------------------------------
        # ALTITUDE FILTERING
        # -------------------------------
        altitude_filtered = filter_by_altitude(top_crops, altitude)

        # fallback if empty
        final_crops = altitude_filtered if altitude_filtered else top_crops[:3]

        # Pastikan minimal 3 crop tersedia
        while len(final_crops) < 3:
            final_crops.append({"crop": "Unknown", "probability": 0.0})

        result = {
            "status": "success",
            "prediction": final_crops[0]["crop"],
            "confidence": final_crops[0]["probability"],
            "second_prediction": final_crops[1]["crop"],
            "second_confidence": final_crops[1]["probability"],
            "third_prediction": final_crops[2]["crop"],
            "third_confidence": final_crops[2]["probability"],
            "data": {
                "altitude": altitude,
                "top_crops": final_crops
            }
        }

        print(json.dumps(result))

    except Exception as e:
        print(json.dumps({
            "status": "error",
            "message": str(e)
        }))
        sys.exit(1)


# ======================================================
# ENTRY POINT
# ======================================================
if __name__ == "__main__":
    input_data = json.loads(sys.stdin.read())
    predict_crop(input_data)