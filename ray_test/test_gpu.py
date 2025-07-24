import ray
import torch
import time

@ray.remote(num_gpus=1)
def long_gpu_task(task_id):
    if torch.cuda.is_available():
        device = torch.device("cuda")
        gpu_name = torch.cuda.get_device_name()
        gpu_id = torch.cuda.current_device()
        
        print(f"Task {task_id} starting on GPU {gpu_id}: {gpu_name}")
        
        # Run GPU work for 3 minutes
        end_time = time.time() + 180  # 3 minutes
        iteration = 0
        
        while time.time() < end_time:
            # Some GPU work
            x = torch.randn(2000, 2000, device=device)
            y = torch.randn(2000, 2000, device=device)
            z = torch.mm(x, y)
            iteration += 1
            time.sleep(1)  # Brief pause
            
        return f"Task {task_id} completed {iteration} iterations on GPU {gpu_id}: {gpu_name}"
    else:
        return f"Task {task_id}: No GPU available"

# Test it
# ray.init(address="ray://raycluster-kuberay-head-svc:10001")
ray.init(address="ray://10.244.35.106:10001")

# Launch 3 GPU tasks simultaneously
futures = [long_gpu_task.remote(i) for i in range(3)]

print("Started 3 GPU tasks - check cluster scaling with: kubectl get pods -n ray -w")
results = ray.get(futures)

for result in results:
    print(result)