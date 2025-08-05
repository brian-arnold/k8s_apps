#!/usr/bin/env python3
"""
simplified_ray_job.py

Direct import version - no pip install needed.
Copy video_embeddings_cosmos.py to the same directory.
"""

import ray
import os
import sys

import numpy as np
from pathlib import Path

@ray.remote(num_gpus=1)
def process_video_batch(video_files: list, data_folder: str, output_folder: str):
    """
    Ray-decorated function that processes a batch of videos
    """

    from video_embeddings.video_embeddings_cosmos import load_model, compute_embeddings, compute_motion_score

    print(f"Processing batch of {len(video_files)} videos on GPU")
    
    # Load model once per batch
    model, preprocess = load_model()
    
    results = {"processed": 0, "failed": 0}
    
    for video_file in video_files:
        try:
            video_path = os.path.join(data_folder, video_file.strip())
            print(f"Processing {video_path}")
            
            # Compute embeddings
            global_embedding, frame_embeddings = compute_embeddings(
                model, preprocess, video_path
            )
            motion_score = compute_motion_score(frame_embeddings)
            
            # Save embeddings
            base_name = Path(video_file).stem
            output_file = os.path.join(output_folder, f"{base_name}_embedding.npz")
            
            os.makedirs(os.path.dirname(output_file), exist_ok=True)
            np.savez(
                output_file,
                global_embedding=global_embedding,
                motion_score=np.array(motion_score, dtype=np.float32),
            )
            
            results["processed"] += 1
            print(f"Successfully processed {video_file}")
            
        except Exception as e:
            results["failed"] += 1
            print(f"Failed to process {video_file}: {e}")
    
    return results

    
################################################################################
# Set input variables
################################################################################
# directory containing the video files to process; options are 'eco_centric' or 'human_centric' in the '/enigma-videos/movies' directory
data_folder = "/enigma-videos/movies/eco_centric"
# directory where embedding will be saved
output_folder = "/lab/users/barnold/k8s_apps/ray_test/test_clusters/adriano_video_embeddings/test_out"
# file containing the list of video files to process, one per line; this will be used to create batches
input_files = "/lab/users/barnold/k8s_apps/ray_test/test_jobs/adriano_selection_pipeline/data.txt" 
# number of videos per batch
batch_size = 20

################################################################################
# Initialize Ray and distribute tasks
################################################################################

print("Connecting to Ray Cluster, make sure you have locally installed Ray 2.48.0!")
ray.init(address="ray://raycluster-adriano-kuberay-head-svc.ray.svc.cluster.local:10001")

print(f"Starting Ray job with {ray.cluster_resources()} resources")
print(f"Data folder: {data_folder}")
print(f"Output folder: {output_folder}")
print(f"Input files: {input_files}")

# Ensure output folder exists
os.makedirs(output_folder, exist_ok=True)

# Read all video files
with open(input_files, "r") as f:
    all_videos = [line.strip() for line in f if line.strip()]

print(f"Found {len(all_videos)} videos to process")

# Create batches
batches = [all_videos[i:i + batch_size] for i in range(0, len(all_videos), batch_size)]
print(f"Created {len(batches)} batches of size {batch_size}")

# Submit all batches to Ray
futures = [
    process_video_batch.remote(batch, data_folder, output_folder)
    for batch in batches
]

# Wait for completion
results = ray.get(futures)

total_processed = sum(r["processed"] for r in results)
total_failed = sum(r["failed"] for r in results)

print(f"All batches completed!")
print(f"Total processed: {total_processed}")
print(f"Total failed: {total_failed}")
