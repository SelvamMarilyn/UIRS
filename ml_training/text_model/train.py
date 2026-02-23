import os
import pickle
import argparse
import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.svm import SVC
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

# Default paths matching backend_fastapi/app/services/text_classifier.py
MODEL_FILENAME = "text_classifier.pkl"
VECTORIZER_FILENAME = "tfidf_vectorizer.pkl"

def get_dummy_data():
    """Generates synthetic data for verification."""
    texts = [
        # Road Damage (Dept 0)
        "huge pothole on main street", "road crack near bridge", "pavement is uneven",
        "deep crater in middle of road", "asphalt melting due to heat",
        # Sanitation (Dept 1)
        "overflowing trash bin", "garbage dump on sidewalk", "foul smell from waste",
        "litter everywhere in park", "sewage leak near drain",
        # Electrical (Dept 2)
        "street lamp flicker", "no lights in alleyway", "exposed electrical wire",
        "broken lamp post", "dark street due to lighting failure"
    ]
    
    # Severity: 0: low, 1: medium, 2: high, 3: critical
    severity = [2, 1, 0, 3, 1, 2, 2, 1, 1, 3, 0, 2, 3, 1, 2]
    
    # Dept: 0: road, 1: waste, 2: lights
    dept = [0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2]
    
    return texts, severity, dept

def train_and_save(texts, severity_labels, dept_labels, output_dir):
    """
    Trains TF-IDF + SVM and saves vectorizer and model dict.
    """
    print("Pre-processing and vectorizing...")
    vectorizer = TfidfVectorizer(max_features=1000, ngram_range=(1, 2), stop_words='english')
    X = vectorizer.fit_transform(texts)
    
    print("Training severity model...")
    severity_model = SVC(kernel='linear', probability=True)
    severity_model.fit(X, severity_labels)
    
    print("Training department model...")
    dept_model = SVC(kernel='linear', probability=True)
    dept_model.fit(X, dept_labels)
    
    # Save outputs
    os.makedirs(output_dir, exist_ok=True)
    
    vectorizer_path = os.path.join(output_dir, VECTORIZER_FILENAME)
    with open(vectorizer_path, 'wb') as f:
        pickle.dump(vectorizer, f)
    print(f"Vectorizer saved to {vectorizer_path}")
    
    models_path = os.path.join(output_dir, MODEL_FILENAME)
    model_dict = {
        'severity': severity_model,
        'department': dept_model
    }
    with open(models_path, 'wb') as f:
        pickle.dump(model_dict, f)
    print(f"Models saved to {models_path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train Urban AI Text Classifier")
    parser.add_argument("--csv", type=str, help="Path to dataset CSV (must have 'text', 'severity', 'department' columns)")
    parser.add_argument("--dummy", action="store_true", help="Generate dummy models for testing")
    
    args = parser.parse_args()
    
    output_dir = os.path.dirname(__file__)
    
    if args.dummy:
        print("Training with dummy data...")
        texts, severity, dept = get_dummy_data()
        train_and_save(texts, severity, dept, output_dir)
    elif args.csv:
        import pandas as pd
        df = pd.read_csv(args.csv)
        # Ensure column names match
        texts = df['text'].astype(str).tolist()
        severity = df['severity'].tolist()
        dept = df['department'].tolist()
        train_and_save(texts, severity, dept, output_dir)
    else:
        print("Please provide --csv or use --dummy")
