# gpu-setup

One-command deployment of [Karpathy's autoresearch](https://github.com/karpathy/autoresearch) on Akash Network. Spins up an H100/A100 GPU container, installs everything, downloads the dataset, and gives you SSH access.

## Prerequisites

- An [Akash Console](https://console.akash.network) account with credits
- An API key from Akash Console (starts with `ac.sk.`)
- `jq` and `sshpass` installed locally

```bash
# macOS
brew install jq hudochenkov/sshpass/sshpass

# Ubuntu/Debian
sudo apt-get install -y jq sshpass
```

## Setup

Create a `.env` file in the repo root:

```
AKASH_API_KEY=ac.sk.production.your-key-here
```

## Deploy

```bash
cd gpu-setup
./deploy.sh
```

This will:
1. Create a deployment on Akash ($5 escrow deposit)
2. Wait for GPU provider bids
3. Accept the cheapest H100/A100 bid
4. Boot the container with PyTorch + CUDA
5. Auto-install autoresearch, download data, train tokenizer
6. Print SSH credentials when ready

Takes ~5 minutes for the container to fully set up.

## Connect

```bash
sshpass -p 'autoresearch' ssh -p <PORT> root@<HOST>
```

The deploy script prints the exact command. Once in:

```bash
cd /workspace/autoresearch

# run a single training experiment (~5 min)
uv run train.py

# or start the autonomous research loop with claude
claude "Read program.md and let's kick off a new experiment"
```

## Other commands

```bash
# check deployment status
./status.sh

# tear down and recover remaining deposit
./teardown.sh
```

## What you get

- PyTorch 2.5.1 + CUDA 12.4 container
- H100 80GB or A100 80GB GPU
- 8 CPU cores, 64GB RAM, 30GB storage
- autoresearch repo cloned and ready at `/workspace/autoresearch`
- SSH access with password `autoresearch`

## Cost

GPU pricing varies by provider. With $100 in Akash credits you can run for several hours. The deploy script picks the cheapest available bid automatically.

## Customizing

Edit `deploy.yaml` to change:
- GPU model (default: H100 or A100)
- CPU/memory/storage allocation
- Docker base image
- Startup commands
