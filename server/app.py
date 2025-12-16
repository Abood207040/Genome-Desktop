import joblib
import pandas as pd
from flask import Flask, request, jsonify
import os
import traceback
from model_class import MergedModel  # Assuming the model class is defined in model_class.py

app = Flask(__name__)

# Initialize model as None
model = None

# Log the current working directory to check the path
print(f"Current working directory: {os.getcwd()}")

# Load the model
print("Loading model...")
try:
    model = joblib.load("merged_model.pkl")
    print("Model loaded successfully!")
except Exception as e:
    # Print the full traceback to get more details on why the model isn't loading
    print("Error loading model:")
    traceback.print_exc()
    model = None

@app.route("/")
def home():
    return "Genomic Model API is running!"

@app.route("/predict", methods=["POST"])
def predict():
    # If model is not loaded, return an error
    if model is None:
        print("Model is not loaded")
        return jsonify({"error": "Model could not be loaded"}), 500

    # Check if the 'file' is in the request
    if "file" not in request.files:
        print("No file found in the request")
        return jsonify({"error": "No CSV file uploaded"}), 400

    file = request.files["file"]
    print(f"Received file: {file.filename}")

    try:
        # Read the CSV file into a pandas DataFrame
        df = pd.read_csv(file)
        print("CSV loaded successfully")

        # Check if the DataFrame is empty
        if df.empty:
            print("CSV is empty")
            return jsonify({"error": "CSV is empty"}), 400

        # Convert the first row of the CSV to a dictionary
        input_dict = df.iloc[0].to_dict()
        print(f"Converted input data to dictionary: {input_dict}")

        # Adjust the column names if necessary
        if 'Chrom' in input_dict:
            input_dict['Chromosome'] = input_dict.pop('Chrom')  # Rename 'Chrom' to 'Chromosome'

        print(f"Adjusted input data: {input_dict}")

        # Check if the model has a 'predict' method and use it to get predictions
        if hasattr(model, 'predict'):
            try:
                disease, treatment = model.predict(input_dict)
                print(f"Prediction: Disease: {disease}, Treatment: {treatment}")
                return jsonify({
                    "status": "success",
                    "predicted_disease": disease,
                    "predicted_treatment": treatment
                })
            except Exception as e:
                print(f"Error during model prediction: {str(e)}")
                return jsonify({"error": f"Error during prediction: {str(e)}"}), 500
        else:
            print("Model does not have 'predict' method")
            return jsonify({"error": "Model does not have a 'predict' method"}), 500

    except Exception as e:
        print(f"Error during processing: {str(e)}")
        return jsonify({"error": f"Error during processing: {str(e)}"}), 500

if __name__ == "__main__":
    # Run Flask with debug mode enabled for better error logging
    app.run(host="0.0.0.0", port=5000, debug=True)
