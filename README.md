# polyresearch

Running [Karpathy's autoresearch](https://github.com/karpathy/autoresearch) on decentralized GPU compute via [Akash Network](https://akash.network).

Autoresearch lets an AI agent autonomously experiment on neural network training code. It modifies the architecture, trains for 5 minutes, checks if the result improved, keeps or discards, and repeats. This repo adds one-command GPU deployment on Akash so you can run it without owning hardware.

## Repo structure

```
autoresearch/                # Karpathy's original files (forked)
├── prepare.py               # data download, tokenizer, eval (do not modify)
├── train.py                 # model + training loop (agent modifies this)
├── program.md               # instructions for the AI agent
├── analysis.ipynb           # notebook for analyzing results
├── pyproject.toml           # dependencies
└── uv.lock                  # lockfile

gpu-setup/                   # Akash deployment scripts
├── README.md                # setup guide
├── deploy.sh                # one-command deploy
├── teardown.sh              # close deployment
├── status.sh                # check deployment status
└── deploy.yaml              # Akash SDL (container spec)
```

## Quick start

```bash
# 1. Add your Akash API key
echo "AKASH_API_KEY=ac.sk.production.your-key" > .env

# 2. Deploy an H100 on Akash
cd gpu-setup && ./deploy.sh

# 3. SSH into the container
sshpass -p 'autoresearch' ssh -p <PORT> root@<HOST>

# 4. Run a training experiment
cd /workspace/autoresearch && uv run train.py

# 5. Or start the autonomous loop
claude "Read program.md and let's kick off a new experiment"
```

See [gpu-setup/README.md](gpu-setup/README.md) for detailed instructions.

## Links

- [autoresearch](https://github.com/karpathy/autoresearch) — Karpathy's original repo
- [autoresearch-at-home](https://github.com/mutable-state-inc/autoresearch-at-home) — distributed swarm version
- [Ensue Network](https://www.ensue-network.ai/autoresearch) — shared memory layer for agent collaboration
- [Akash Network](https://akash.network) — decentralized GPU marketplace
