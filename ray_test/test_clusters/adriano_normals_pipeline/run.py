#!/usr/bin/env python3
"""
ray_connectivity_test.py

Simple test to verify Ray cluster connectivity
"""

import ray
import time

@ray.remote
def simulate_work_batch(batch_id: int, work_duration: int = 30):
    """
    Simulate computational work that takes time - tests worker allocation and autoscaling
    """
    import time
    import random
    
    start_time = time.time()
    node_id = ray.get_runtime_context().get_node_id()
    
    print(f"🔥 Batch {batch_id}: Starting work on node {node_id[:8]}...")
    
    # Simulate some CPU-intensive work
    result = 0
    for i in range(work_duration * 100000):
        result += random.random() ** 0.5
    
    # Add some sleep to simulate I/O or mixed workload
    time.sleep(random.uniform(10, 20))
    
    end_time = time.time()
    duration = end_time - start_time
    
    return {
        "batch_id": batch_id,
        "node_id": node_id[:8],
        "duration": round(duration, 2),
        "result_sample": round(result, 2)
    }


def test_ray_autoscaling():
    """Test Ray cluster connectivity, resource allocation, and autoscaling"""
    
    try:
        print("Attempting to connect to Ray cluster...")
        
        # Connect to your Ray cluster
        ray.init(address="ray://raycluster-adriano-normals-kuberay-head-svc.ray.svc.cluster.local:10001")
        
        print("✅ Successfully connected to Ray cluster!")
        
        # Check initial cluster resources
        initial_resources = ray.cluster_resources()
        print(f"📊 Initial cluster resources: {initial_resources}")
        
        # Submit 5 batches of work to test autoscaling
        print("\n🚀 Submitting 5 work batches to test autoscaling...")
        
        batch_futures = []
        for i in range(5):
            future = simulate_work_batch.remote(batch_id=i+1, work_duration=30)
            batch_futures.append(future)
            print(f"   📤 Submitted batch {i+1}")
        
        print(f"\n⏳ Waiting for {len(batch_futures)} batches to complete...")
        print("   (This will take 30-50 seconds - watch for autoscaling!)")
        
        # Wait for all batches and collect results
        start_wait = time.time()
        results = ray.get(batch_futures)
        total_wait = time.time() - start_wait
        
        # Display results
        print(f"\n🎉 All batches completed in {total_wait:.1f} seconds!")
        print("\n📋 Batch Results:")
        for result in results:
            print(f"   Batch {result['batch_id']}: {result['duration']}s on node {result['node_id']}")
        
        # Check final cluster resources
        final_resources = ray.cluster_resources()
        print(f"\n📊 Final cluster resources: {final_resources}")
        
        # Check if we used multiple nodes (indicates scaling worked)
        unique_nodes = set(r['node_id'] for r in results)
        print(f"\n🔍 Work distributed across {len(unique_nodes)} nodes: {unique_nodes}")
        
        if len(unique_nodes) > 1:
            print("✅ Autoscaling appears to be working - multiple nodes used!")
        else:
            print("ℹ️  All work ran on single node - may need more load to trigger scaling")
        
        return True
        
    except Exception as e:
        print(f"❌ Ray cluster test FAILED: {e}")
        return False
        
    finally:
        # Clean up
        try:
            ray.shutdown()
            print("\n🔌 Ray connection closed")
        except:
            pass

if __name__ == "__main__":
    test_ray_autoscaling()