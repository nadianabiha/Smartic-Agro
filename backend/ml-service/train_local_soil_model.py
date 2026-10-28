"""Train/evaluate a Smartic Agro crop classifier from a verified local-soil CSV.

Expected columns: N,P,K,temperature,humidity,pH,crop. Optional feature: ec.
The script never overwrites the production bundle unless evaluation passes the
minimum macro-F1 threshold and --output explicitly points to the desired file.
"""
import argparse
import json
from pathlib import Path

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, classification_report, f1_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.pipeline import Pipeline

BASE_DIR = Path(__file__).resolve().parent
REQUIRED = ["N", "P", "K", "temperature", "humidity", "pH", "crop"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv", help="CSV hasil pengukuran tanah lokal yang sudah diverifikasi")
    parser.add_argument("--output", default=str(BASE_DIR / "models" / "crop_model_bundle_local_candidate.joblib"))
    parser.add_argument("--test-size", type=float, default=0.2)
    parser.add_argument("--min-macro-f1", type=float, default=0.65)
    parser.add_argument("--random-state", type=int, default=42)
    args = parser.parse_args()

    data = pd.read_csv(args.csv)
    missing = [c for c in REQUIRED if c not in data.columns]
    if missing:
        raise SystemExit(f"Kolom wajib tidak ditemukan: {', '.join(missing)}")
    feature_columns = ["N", "P", "K", "temperature", "humidity", "pH"]
    if "ec" in data.columns and data["ec"].notna().all():
        feature_columns.append("ec")
    data = data[feature_columns + ["crop"]].copy()
    for col in feature_columns:
        data[col] = pd.to_numeric(data[col], errors="coerce")
    data["crop"] = data["crop"].astype(str).str.strip()
    data = data.dropna()
    data = data[data["crop"] != ""]
    if len(data) < 30:
        raise SystemExit(f"Data valid hanya {len(data)} baris; minimal 30 untuk uji awal, lebih banyak lebih baik.")
    counts = data["crop"].value_counts()
    if len(counts) < 2 or counts.min() < 2:
        raise SystemExit("Dataset perlu minimal 2 kelas tanaman dan minimal 2 sampel per kelas.")

    X = data[feature_columns]
    y = data["crop"]
    stratify = y if counts.min() >= 2 else None
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=args.test_size, random_state=args.random_state, stratify=stratify
    )
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    model = RandomForestClassifier(n_estimators=400, class_weight="balanced", random_state=args.random_state)
    model.fit(X_train_scaled, y_train)
    predicted = model.predict(X_test_scaled)
    accuracy = float(accuracy_score(y_test, predicted))
    macro_f1 = float(f1_score(y_test, predicted, average="macro", zero_division=0))
    report = classification_report(y_test, predicted, output_dict=True, zero_division=0)
    metrics = {
        "rows_used": int(len(data)), "train_rows": int(len(X_train)), "test_rows": int(len(X_test)),
        "classes": sorted(y.unique().tolist()), "feature_columns": feature_columns,
        "accuracy": accuracy, "macro_f1": macro_f1,
        "classification_report": report,
        "warning": "Evaluasi holdout awal; bukan jaminan generalisasi. Validasi lokasi/musim dan lakukan uji lapangan."
    }
    metrics_path = Path(args.output).with_suffix(".metrics.json")
    metrics_path.parent.mkdir(parents=True, exist_ok=True)
    metrics_path.write_text(json.dumps(metrics, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps({k: metrics[k] for k in ["rows_used", "train_rows", "test_rows", "classes", "feature_columns", "accuracy", "macro_f1"]}, indent=2, ensure_ascii=False))
    print(f"Laporan evaluasi: {metrics_path}")
    if macro_f1 < args.min_macro_f1:
        raise SystemExit(f"Kandidat tidak disimpan: macro-F1 {macro_f1:.3f} di bawah ambang {args.min_macro_f1:.3f}.")

    bundle = {"model": model, "scaler": scaler, "labels": model.classes_.tolist(), "feature_columns": feature_columns,
              "training_metadata": {"dataset": str(Path(args.csv).resolve()), "rows_used": len(data), "accuracy": accuracy, "macro_f1": macro_f1}}
    joblib.dump(bundle, args.output)
    print(f"Kandidat model disimpan: {args.output}")
    print("Model kandidat tidak menggantikan model aktif secara otomatis. Review metrik dan dataset sebelum deployment.")


if __name__ == "__main__":
    main()
