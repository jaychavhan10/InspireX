from flask import Flask, request, jsonify
from flask_cors import CORS
import traceback
import nltk
import sys
import warnings

# Suppress scikit-learn warnings early
warnings.filterwarnings('ignore')

from ml_pipeline import process_idea

app = Flask(__name__)
CORS(app)

# Ensure NLTK requirements are met for summarization
print("Checking NLP dependencies...")
try:
    nltk.download('punkt', quiet=True)
    nltk.download('punkt_tab', quiet=True)
    print("NLP dependencies ready.")
except Exception as e:
    print(f"Warning: Could not download NLTK data: {e}")

@app.route('/', methods=['GET'])
def health():
    return "Backend is running!"

@app.route('/process', methods=['POST'])
def process():
    try:
        # Use force=True to handle cases where Content-Type isn't set perfectly
        data = request.get_json(force=True)
        if not data or 'text' not in data:
            return jsonify({"error": "No text provided"}), 400
            
        text = data['text']
        print(f"\n[Request] Analyzing: {text[:50]}...")

        result = process_idea(text)
        
        print(f"[Success] Similarity: {result.get('similarity_status')}")
        return jsonify(result)

    except Exception as e:
        print("\n!!! ERROR IN BACKEND !!!")
        traceback.print_exc() # This prints the EXACT line that failed
        return jsonify({"error": str(e), "trace": traceback.format_exc()}), 500

if __name__ == '__main__':
    print("Starting InspireX Backend on port 5000...")
    app.run(host='0.0.0.0', port=5000, debug=False)
