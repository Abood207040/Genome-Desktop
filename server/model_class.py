import pandas as pd
import numpy as np

# تعريف الكلاس اتنقل هنا
class MergedModel:
    def __init__(self, disease_model, treatment_model, enc_disease, enc_treatment, le_disease, le_treatment, features):
        self.disease_model = disease_model
        self.treatment_model = treatment_model
        self.enc_disease = enc_disease
        self.enc_treatment = enc_treatment
        self.le_disease = le_disease
        self.le_treatment = le_treatment
        self.features = features

    def _encode(self, input_dict, enc):
        inp = input_dict.copy()
        for col in ["Chromosome", "Gene", "Variant_Type", "CLNSIG", "Risk_Level"]:
            if col not in inp:
                raise ValueError(f"Missing {col}")
            val = str(inp[col])
            le = enc[col]
            if val not in le.classes_:
                raise ValueError(f"Unseen value {val} for {col}")
            inp[col] = le.transform([val])[0]
        
        if "Risk_Prob" not in inp:
            raise ValueError("Missing Risk_Prob")
        inp["Risk_Prob"] = float(inp["Risk_Prob"])
        
        return pd.DataFrame([inp])[self.features]

    def predict(self, input_dict):
        Xd = self._encode(input_dict, self.enc_disease)
        Xt = self._encode(input_dict, self.enc_treatment)
        d_enc = self.disease_model.predict(Xd)[0]
        t_enc = self.treatment_model.predict(Xt)[0]
        return (self.le_disease.inverse_transform([d_enc])[0],
                self.le_treatment.inverse_transform([t_enc])[0])