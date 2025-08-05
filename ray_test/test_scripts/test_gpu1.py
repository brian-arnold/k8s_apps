import ray
import time
import subprocess
import os


@ray.remote(num_gpus=1)
def gpu_task(task_id):
    try:
        from spikeinterface import core
        
        # Check if GPU is allocated via environment variables
        gpu_visible = os.environ.get('CUDA_VISIBLE_DEVICES', 'None')
        
        # Try to get GPU info via nvidia-smi
        result = subprocess.run(['nvidia-smi', '--query-gpu=name', '--format=csv,noheader'], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            gpu_name = result.stdout.strip().split('\n')[0] if result.stdout.strip() else "Unknown GPU"
            print(f"Task {task_id} starting on GPU {gpu_visible}: {gpu_name}")
        else:
            gpu_name = "GPU detection failed"
            print(f"Task {task_id} starting, GPU_VISIBLE_DEVICES: {gpu_visible}")
        
        end_time = time.time() + 30  
        iteration = 0
        
        while time.time() < end_time:
            # Simulate some work
            _ = sum(i**2 for i in range(10000))
            iteration += 1
            time.sleep(1)
            
        return f"Task {task_id} completed {iteration} iterations on GPU {gpu_visible}: {gpu_name}"
    except Exception as e:
        return f"Task {task_id} error: {str(e)}"

# Test it
runtime_env = {"pip": ["spikeinterface"]}
ray.init(address="ray://raycluster-kuberay-head-svc.ray.svc.cluster.local:10001",
         runtime_env=runtime_env)

tasks = 10
# Launch 10 GPU tasks simultaneously
futures = [gpu_task.remote(i) for i in range(10)]
print("Started 10 GPU tasks - check cluster scaling with: kubectl get pods -n ray -w")
results = ray.get(futures)

for result in results:
    print(result)