"""
Fix scikit-learn model incompatibility by converting pickle files to joblib format
"""
import warnings
warnings.filterwarnings('ignore')

import pickle
import joblib
import os
import sys

print("[FixModels] Starting model conversion...")
print("[FixModels] Current working directory:", os.getcwd())

# List of model files to convert
model_files = [
    'rating_model.pkl',
    'tfidf.pkl',
    'sim_vectorizer.pkl',
    'tfidf_matrix.pkl',
    'price_model.pkl',
    'ideas_data.pkl',
]

for model_file in model_files:
    try:
        print(f"\n[FixModels] Loading {model_file}...")
        # Try loading with pickle
        try:
            with open(model_file, 'rb') as f:
                # Try with different protocols
                try:
                    obj = pickle.load(f, encoding='latin1')
                except:
                    f.seek(0)
                    obj = pickle.load(f)
            print(f"[FixModels] ✓ Loaded {model_file} with pickle")
        except Exception as e:
            print(f"[FixModels] ✗ Pickle failed: {e}")
            # Try joblib
            try:
                obj = joblib.load(model_file)
                print(f"[FixModels] ✓ Loaded {model_file} with joblib")
            except Exception as e2:
                print(f"[FixModels] ✗ Joblib failed: {e2}")
                continue
        
        # Save with joblib (more compatible with sklearn)
        joblib_file = model_file.replace('.pkl', '.joblib')
        joblib.dump(obj, joblib_file, compress=3)
        print(f"[FixModels] ✓ Saved as {joblib_file}")
        
    except Exception as e:
        print(f"[FixModels] ✗ Error processing {model_file}: {e}")

print("\n[FixModels] Conversion complete!")
