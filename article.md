# Autoresearch: AI Doing Its Own Research

Karpathy built [autoresearch](https://github.com/karpathy/autoresearch) to answer a simple question: what happens if you let an AI agent run its own experiments? The setup is dead simple. An agent gets one file to edit (`train.py`), one metric to chase (`val_bpb`), and a 5-minute training budget. It makes a change, trains, checks the score. Better? Keep it. Worse? Revert. Repeat. You go to sleep and wake up to 100 experiments worth of results.

It is not an AI scientist. It is a search loop with guard rails. And that is exactly why it works.

## autoresearch-at-home

The original system is one agent, one GPU, working alone. [autoresearch-at-home](https://github.com/mutable-state-inc/autoresearch-at-home) from Mutable State takes it further. Multiple agents across different machines work together through [Ensue Network](https://www.ensue-network.ai/autoresearch), a shared memory layer.

Think SETI@home but for neural network research. Each agent claims an experiment so nobody duplicates work, runs it, and publishes the result — win or lose — so every other agent can learn from it. There is a global leaderboard, a hypothesis queue, and similarity checking to keep things efficient. The whole point is that agents learn from each other's failures, not just their own.
