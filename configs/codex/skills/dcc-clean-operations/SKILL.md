---
name: dcc-clean-operations
description: Clean, project-agnostic Duke Compute Cluster (DCC) operations. Use when Codex needs to move code or data to DCC, choose DCC storage, prepare a repo/environment layout, write DCC runbooks or AGENTS.md notes, request Slurm CPU/GPU interactive or batch jobs, use DCC OnDemand/Jupyter, transfer Coltrane data through Globus, or troubleshoot DCC quotas, partitions, preemption, storage, and job logs.
---

# DCC Clean Operations

## Operating Stance

Treat DCC as a scheduled cluster, not a workstation. Login nodes are for SSH, Git, file organization, light setup, and job submission only; heavy compute must run through Slurm or DCC OnDemand.

Keep the workflow project-agnostic. Inspect the repo's actual build, test, data, and environment conventions before proposing commands. Do not assume Python, conda, uv, Docker, notebooks, or a particular training harness unless the project shows that pattern.

Fail loudly before destructive or expensive operations. Stop and ask when the SSH host, NetID, group access, destination storage class, data size, partition name, runtime, GPU type, checkpointing strategy, or overwrite/delete behavior is unclear.

Before writing runnable DCC commands or project-specific DCC documentation, read [references/dcc-runbook.md](references/dcc-runbook.md).

## Standard Workflow

1. Identify the minimum required context:
   - `NETID`
   - DCC login method or current shell location
   - DCC group/account, project/repo path, and source of truth
   - data source, size, mutability, and destination
   - CPU/GPU, memory, walltime, Slurm account, partition, and preemption tolerance
   - whether the task is debugging, production run, transfer, or cleanup

2. Choose storage intentionally:
   - Put stable code, env definitions, small results, and durable project state on persistent storage such as group or PhD allocation space.
   - Put active large data, caches, scratch files, and large run outputs on `/work/NETID` or the appropriate scratch location.
   - Do not put archival data on purge-backed scratch.
   - Avoid placing long-lived environments directly on `/work`; keep envs on persistent group, PhD allocation, or home storage when possible and point caches to `/work`.

3. Move code through Git when possible:
   - Commit and push local or Coltrane branches before cloning on DCC.
   - Keep project-specific generated outputs out of Git unless the repo already tracks them.
   - If writing AGENTS.md, include only operational project-specific DCC facts, not generic DCC prose.

4. Move large data through Globus or an explicit transfer plan:
   - Prefer Globus for Coltrane-to-DCC large transfers.
   - Never duplicate large Coltrane data just to expose it for transfer; move into the transfer staging path and move it back after verification if needed.
   - Verify destination permissions, quota, and purge policy before transfer.

5. Pick the execution mode:
   - Use `srun --pty ... bash -i` for short interactive debugging.
   - Use `sbatch` for long-running jobs, training, sweeps, and anything that must survive a local disconnect.
   - Use DCC OnDemand/Jupyter only when notebooks are actually part of the workflow.

6. Verify and monitor:
   - Check `sinfo`, `squeue -u "$USER"`, logs, quotas, and output directories.
   - For scavenger/preemptible partitions, require checkpointing before recommending long jobs.
   - Summarize exact commands run and exact paths created so the user can reproduce or roll back.

## Command Discipline

Use placeholders until facts are known: `NETID`, `GROUP`, `ACCOUNT`, `PROJECT`, `RUN_NAME`, `REPO_URL`, `DATA_SOURCE`, `DATA_DEST`, `PARTITION`, `GPU_GRES`, `WALLTIME`, `JOB_ID`.

Prefer commands that are inspectable and reversible:

- Run `pwd`, `hostname`, `whoami`, `git status`, and quota checks before changing remote state.
- Use `mkdir -p` for expected directories.
- Use `rsync --dry-run` before `rsync` when transfer semantics are uncertain.
- Avoid `rm -rf`, broad `mv`, and recursive copies of large data unless the user explicitly approved the exact source and destination.
- Capture Slurm stdout/stderr into deterministic `logs/` paths.

When DCC docs, login details, partition names, quotas, or lab paths conflict with memory or old notes, trust current DCC output and official docs over this skill.
