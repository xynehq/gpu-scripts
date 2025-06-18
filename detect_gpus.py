import torch

def main():
    num_gpus = torch.cuda.device_count()
    print(num_gpus)

if __name__ == "__main__":
    main()
