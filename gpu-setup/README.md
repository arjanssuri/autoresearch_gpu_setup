# gpu-setup

Run [Karpathy's autoresearch](https://github.com/karpathy/autoresearch) on a cloud GPU through [Akash Network](https://akash.network). No hardware needed.

## Requirements

You need four things before starting:

1. **An Akash Console account** — sign up at [console.akash.network](https://console.akash.network). New accounts get free credits.
2. **An Akash API key** — grab one from the Console dashboard. It starts with `ac.sk.`.
3. **jq** — a command line JSON tool. Install it:
   - Mac: `brew install jq`
   - Linux: `sudo apt-get install -y jq`
4. **sshpass** — lets you SSH with a password in one command:
   - Mac: `brew install hudochenkov/sshpass/sshpass`
   - Linux: `sudo apt-get install -y sshpass`

## Steps

### 1. Clone the repo

```bash
git clone https://github.com/arjanssuri/polyresearch.git
cd polyresearch
```

### 2. Add your API key

Create a file called `.env` in the repo root:

```bash
echo "AKASH_API_KEY=ac.sk.production.your-key-here" > .env
```

Replace `your-key-here` with your actual key.

### 3. Deploy

```bash
cd gpu-setup
./deploy.sh
```

This takes about a minute. It will:
- Put $5 from your credits into escrow
- Find the cheapest available H100 or A100
- Spin up a container with PyTorch and CUDA pre-installed
- Clone autoresearch and download the training data
- Print your SSH connection details

### 4. Wait for setup

The container needs ~5 minutes after deploy to finish installing everything. You can check if it's ready:

```bash
./status.sh
```

Look for `"ready": 1`. That means it's good to go.

### 5. SSH in

The deploy script prints your exact SSH command. It looks like this:

```bash
sshpass -p 'autoresearch' ssh -p <PORT> root@<HOST>
```

Copy and run it. You're now on a machine with an H100 GPU.

### 6. Run autoresearch

```bash
cd /workspace/autoresearch
uv run train.py
```

That runs one 5-minute training experiment. To start the full autonomous loop where the AI runs experiments on its own:

```bash
# install claude code
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
npm install -g @anthropic-ai/claude-code

# set your anthropic key
export ANTHROPIC_API_KEY=your-anthropic-key

# start the loop
claude "Read program.md and let's kick off a new experiment"
```

Walk away. Come back to results.

### 7. Tear down when done

Back on your local machine:

```bash
cd gpu-setup
./teardown.sh
```

This closes the deployment and returns any unspent credits.

## What you get

- NVIDIA H100 80GB or A100 80GB
- 8 CPU cores, 64GB RAM, 30GB storage
- PyTorch 2.5.1 + CUDA 12.4
- autoresearch cloned and ready at `/workspace/autoresearch`
- SSH password: `autoresearch`

## Cost

The deploy script picks the cheapest GPU bid automatically. With $100 in credits you can run for several hours. The $5 escrow deposit gets returned (minus usage) when you tear down.

## Customizing

Edit `deploy.yaml` if you want to change the GPU model, memory, storage, or base Docker image.
