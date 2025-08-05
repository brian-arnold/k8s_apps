#!/usr/bin/env python3
"""
simplified_ray_job.py

Direct import version - no pip install needed.
Copy video_embeddings_cosmos.py to the same directory.
"""

import ray
import os
import sys

# Add current directory to path
sys.path.append('/lab/users/barnold/enigma_repos/selection_pipeline/src/selection_pipeline')

# Import the functions directly
from video_embeddings_cosmos import load_model, compute_embeddings, compute_motion_score
from omegaconf import DictConfig
import numpy as np
from pathlib import Path

@ray.remote(num_gpus=1)
def process_video_batch(video_files: list, data_folder: str, output_folder: str):
    """
    Ray-decorated function that processes a batch of videos
    """
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

def main():
    """Main Ray job coordinator"""
    ray.init()
    
    # Get configuration from environment
    data_folder = os.getenv("DATA_FOLDER", "/data")
    output_folder = os.getenv("OUTPUT_FOLDER", "/output") 
    input_files = os.getenv("INPUT_FILES", "/data.txt")
    batch_size = int(os.getenv("BATCH_SIZE", "5"))
    
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

if __name__ == "__main__":
    main()