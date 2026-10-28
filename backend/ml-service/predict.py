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
    feature_columns = model_bundle.get("feature_columns", ["N", "P", "K", "temperature", "humidity", "pH"])

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

    return filtered


# ======================================================
# PREDICTION FUNCTION
# ======================================================
def predict_crop(data):
    try:
        # -------------------------------
        # INPUT FEATURES (ML)
        # -------------------------------
        input_values = {
            "N": data.get("N"), "P": data.get("P"), "K": data.get("K"),
            "temperature": data.get("temperature"), "humidity": data.get("humidity"),
            "pH": data.get("pH", data.get("ph")), "ec": data.get("ec")
        }
        missing = [column for column in feature_columns if input_values.get(column) is None]
        if missing:
            raise ValueError("Parameter wajib untuk model ini: " + ", ".join(missing))
        features = np.array([[float(input_values[column]) for column in feature_columns]])

        altitude = float(data.get("altitude", 0))

        features_scaled = scaler.transform(features)

        # -------------------------------
        # ML PREDICTION
        # -------------------------------
        proba = model.predict_proba(features_scaled)[0]

        # If altitude > 0, check more candidates for filtering
        num_candidates = 15 if altitude > 0 else 5
        top_indices = np.argsort(proba)[::-1][:num_candidates]
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
        if altitude > 0:
            altitude_filtered = filter_by_altitude(top_crops, altitude)
            # Take top 5 from filtered results
            final_crops = altitude_filtered[:5] if altitude_filtered else top_crops[:5]
        else:
            # No altitude filtering, just return top 5
            final_crops = top_crops[:5]

        result = {
            "status": "success",
            "data": {
                "altitude": altitude,
                "prediction": final_crops[0]["crop"],
                "confidence": final_crops[0]["probability"],
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