"""
Semantic similarity of free-text responses to the leave-one-out group centroid
==============================================================================

Paper:   SI "Behavioral and Text Analysis Pipeline", "In-group semantic
         similarity"; Fig. 1 (right panels)
Purpose: Each response is embedded with a Hebrew sentence-embedding model
         (Hugging Face MPA/sambert: the Tsarfaty-lab Hebrew model AlephBERTGimmel,
         arXiv:2211.15199, as used in the SI). For each video x question
         condition and group, each response's embedding is compared (cosine)
         with the mean embedding of the other members of its own group
         (leave-one-out centroid) - the text analogue of the ISC analysis.

Input    data/behavioral/text/data_final.csv
           text (Hebrew), question (n1/n2, k1/k2, h1/h2: 1 = free description,
           2 = word association; n = Neutral, k = Kosher, h = Chametz),
           group (rel / sec); 21 participants per group (fMRI sample)
Output   results/text/semantic_analysis_results.csv
           text, question, group, cosine_similarity
         The copy used for the paper is data/behavioral/text/semantic_analysis_results.csv
         (read by semantic_similarity_stats.R and fig1_behavior_and_text.R).

Run      pip install -r code/requirements.txt
         python code/text_analysis/semantic_similarity.py
         Internet access is needed once, to download the model from Hugging Face.
         A few minutes on a CPU.

Eldad Aviv, August 2026. Paths adapted to the repository, Oct 2026 (Yohay Zvi).
"""
import pandas as pd
import numpy as np
from sklearn.preprocessing import normalize
from tqdm import tqdm
import matplotlib.pyplot as plt
import seaborn as sns
from sentence_transformers import SentenceTransformer
import torch
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]          # repository root
IN_FILE = ROOT / "data" / "behavioral" / "text" / "data_final.csv"
OUT_FILE = ROOT / "results" / "text" / "semantic_analysis_results.csv"

# ==========================================
# 1. Setup & Model Loading
# ==========================================
# Use GPU if available in Colab
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")

# Load the SentenceTransformer model fine-tuned for Hebrew semantic similarity
model_id = "MPA/sambert"
model = SentenceTransformer(model_id, device=device)

# ==========================================
# 2. Data Loading & Filtering
# ==========================================
data = pd.read_csv(IN_FILE)
print(f"Original data loaded: {len(data)} rows.")

# Filter dataset to retain ONLY 'rel' and 'sec' groups
data = data[data['group'].isin(['rel', 'sec'])].copy()
print(f"Data after filtering for 'rel' and 'sec': {len(data)} rows.")

# ==========================================
# 3. Embedding Extraction
# ==========================================
tqdm.pandas(desc="Extracting sambert Embeddings")

def get_sentence_embedding(text):
    if not isinstance(text, str):
        return np.zeros(768)
    return model.encode(text)

data['embedding'] = data['text'].progress_apply(get_sentence_embedding)

# Initialize a new column for cosine similarity scores
data['cosine_similarity'] = np.nan

# ==========================================
# 4. Centroid & Similarity Calculation (Leave-One-Out)
# ==========================================
groups = ['rel', 'sec']
questions = data['question'].unique()

print("\n--- Calculating LOO Centroid Similarities ---")
for q_name in questions:
    for group_name in groups:
        # Isolate subset for specific question and group
        mask = (data['question'] == q_name) & (data['group'] == group_name)
        subset = data[mask]

        N = len(subset)
        if N <= 1: # LOO requires at least 2 members
            continue

        # Extract and normalize individual embeddings
        V_matrix = np.stack(subset['embedding'].values)
        V_normalized = normalize(V_matrix, norm='l2', axis=1)

        # Calculate the sum of all vectors in the group
        group_sum = np.sum(V_normalized, axis=0)

        # Calculate LOO centroids for each participant i
        # Subtract the participant's own vector from the group sum and divide by N-1
        LOO_centroids = (group_sum - V_normalized) / (N - 1)

        # L2-normalize the LOO centroids
        LOO_centroids_normalized = normalize(LOO_centroids, norm='l2', axis=1)

        # Compute row-wise cosine similarity (dot product between each vector and its LOO centroid)
        similarities = np.einsum('ij,ij->i', V_normalized, LOO_centroids_normalized)

        # Store similarities back in the DataFrame
        data.loc[mask, 'cosine_similarity'] = similarities

# ==========================================
# 5. Export Final Data
# ==========================================
print("\n--- Exporting Final Data ---")
output_filename = OUT_FILE
OUT_FILE.parent.mkdir(parents=True, exist_ok=True)

# Select relevant columns (excluding the massive 768d embedding arrays for a cleaner CSV)
export_df = data[['text', 'question', 'group', 'cosine_similarity']]

# Save to CSV
export_df.to_csv(output_filename, index=False)
print(f"Data successfully saved to {output_filename}.")

# QA: compare with the copy used in the paper
ref = pd.read_csv(ROOT / "data" / "behavioral" / "text" / "semantic_analysis_results.csv")
diff = np.abs(ref['cosine_similarity'].values - data['cosine_similarity'].values).max()
print(f"Max |difference| from the published values: {diff:.2e}")
