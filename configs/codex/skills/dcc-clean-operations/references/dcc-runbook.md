# DCC Runbook

Use this reference for clean, project-agnostic Duke Compute Cluster operations. Replace placeholders before running commands.

## Placeholders

- `NETID`: Duke NetID, also usually the DCC username.
- `GROUP`: DCC group or lab group name, for paths like `/hpc/group/GROUP` and `/datacommons/GROUP`.
- `ACCOUNT`: Slurm account. Often the same as a lab-owned partition/group, but verify with Research Toolkits or Slurm output.
- `PROJECT`: short project slug.
- `RUN_NAME`: run or experiment name.
- `REPO_URL`: Git remote URL.
- `DATA_SOURCE`: local, Coltrane, or existing DCC source path.
- `DATA_DEST`: DCC destination path.
- `PARTITION`: Slurm partition after verification with `sinfo`.
- `GPU_GRES`: Slurm GPU resource request after verification with `sinfo` or DCC docs, such as `gpu:1` or `gpu:<gpu_type>:1`.
- `WALLTIME`: requested runtime for a job, such as `02:00:00` or `1-00:00:00`.
- `JOB_ID`: Slurm job id.

## Current Official References

Prefer live DCC output and official docs over copied notes:

- DCC overview: `https://oit-rc.pages.oit.duke.edu/rcsupportdocs/`
- Slurm guide: `https://oit-rc.pages.oit.duke.edu/rcsupportdocs/dcc/slurm/`
- DCC partitions: `https://oit-rc.pages.oit.duke.edu/rcsupportdocs/dcc/partitions/`
- Storage overview: `https://oit-rc.pages.oit.duke.edu/rcsupportdocs/storage/`
- File transfers: `https://oit-rc.pages.oit.duke.edu/rcsupportdocs/storage/transfers/`
- Globus guide: `https://oit-rc.pages.oit.duke.edu/rcsupportdocs/help/globus/`
- Open OnDemand: `https://oit-rc.pages.oit.duke.edu/rcsupportdocs/OpenOnDemand/`

## Preflight

Run or ask for:

```bash
hostname
whoami
pwd
git status --short
sinfo
squeue -u "$USER"
quota -s -f /work
df -h /hpc/group/GROUP
df -h /datacommons/GROUP
```

Check storage quotas at login or with DCC-supported quota tools before writing large files. Official docs show `quota -s -f /work` for `/work`, `df -h /hpc/group/GROUP` for group space, and `df -h /datacommons/GROUP` for Data Commons. If these commands do not work in the current shell, do not invent replacements; use login output, `du -sh`, DCC docs, or ask the user.

Do not run heavy computation on a login node. Use login nodes for setup and Slurm submission.

For restricted or lab-owned partitions, verify the Slurm account before finalizing commands. DCC docs describe the DCC group as the Slurm account and note that restricted partitions require the correct account.

## Storage Policy

Use the storage class that matches the data lifecycle:

| Path | Intended use | Notes |
| --- | --- | --- |
| `/hpc/home/NETID` | Personal home, dotfiles, lightweight universal tools | Small quota in the source runbook, around 25 GB. Avoid active compute/data. |
| `/hpc/group/GROUP` | Lab/group persistent hot storage | Good for durable project state, shared resources, and stable envs. Official docs describe this as persistent lab group space with snapshots. |
| `/hpc/dctrl/NETID` | Private PhD student persistent working space | Useful for durable per-user project state when available. Verify access before relying on it. |
| `/datacommons/GROUP` | Group cold/archive storage | Good for archival data. Do not use as active compute scratch or high-I/O job storage. |
| `/work/NETID` | Active large data, scratch, cache, run outputs | Fast hot storage with purge policy. Source runbook described up to 20 TB/person and 75-day purge for old files. |
| `/cwork/NETID` | Scratch similar to `/work` | Verify current policy before using. |

Clean default layout:

```bash
mkdir -p /hpc/group/GROUP/NETID/projects/PROJECT
mkdir -p /hpc/group/GROUP/NETID/envs/PROJECT
mkdir -p /work/NETID/PROJECT/{data,runs,cache,logs}
```

Use persistent storage for stable environments when possible:

```bash
/hpc/group/GROUP/NETID/envs/PROJECT
# or, when available and more appropriate:
/hpc/dctrl/NETID/envs/PROJECT
```

Use scratch for caches and large outputs:

```bash
export XDG_CACHE_HOME=/work/NETID/PROJECT/cache
export TMPDIR=/work/NETID/PROJECT/cache/tmp
mkdir -p "$XDG_CACHE_HOME" "$TMPDIR"
```

Avoid creating long-lived conda/venv environments directly on `/work` if they must survive cleanup or purge behavior. A prior DCC setup hit stale file handle issues when an env lived on `/work`; keeping envs on persistent storage and caches on `/work` was cleaner.

## Code Transfer

Prefer Git for code:

```bash
cd /hpc/group/GROUP/NETID/projects
git clone REPO_URL PROJECT
cd PROJECT
git status --short
```

Before leaving the source machine, commit and push active branches:

```bash
git status --short
git branch --show-current
git remote -v
git push
```

If the repo contains project-specific setup instructions, follow those rather than inventing environment tooling.

## Coltrane-to-DCC Large Data Transfer

For large data, use Globus when available. Official DCC docs recommend Globus for transfers to and from DCC.

The Coltrane/Romero source runbook says the lab installed a Globus transfer node on Coltrane and that `/data-transfer` on Coltrane is exposed through Globus. Treat those as lab-specific facts to verify before using.

For the Romero/Coltrane transfer path, package data on Coltrane by moving, not copying:

```bash
mkdir -p ~/dcc-transfer-NETID
# Move large project data into ~/dcc-transfer-NETID intentionally.
mv ~/dcc-transfer-NETID /data-transfer/
```

Do not use `cp -r` for large Coltrane staging unless the user explicitly approves the storage cost.

On DCC, create the destination first:

```bash
mkdir -p /work/NETID
mkdir -p /datacommons/GROUP/NETID
```

Use `/work/NETID` for active project data unless there is a reason not to. Use `/datacommons/GROUP/NETID` for archival data.

If transferring into `/work`, account for purge behavior. If source files have old modification times and the purge uses mtime, update the source timestamps before transfer only after confirming that changing mtimes is acceptable:

```bash
find /data-transfer/dcc-transfer-NETID -type f -exec touch {} +
```

Globus web flow from the source runbook:

1. Log in to Duke Research Toolkits and verify membership in the needed DCC group. For Romero lab Coltrane transfers, the source runbook used `romerolab`.
2. Log in to Globus with Duke credentials.
3. Use the "Duke Compute Cluster (DCC) Data Transfer Node" collection on both sides for Duke-to-Duke transfer.
4. Source path for Coltrane exposure: `/nfs/romero-lab-bme/`.
5. Select `dcc-transfer-NETID`.
6. Destination path: normally `/work/NETID/` for active data or `/datacommons/GROUP/NETID/` for archive.
7. Start the transfer and wait for the completion email.
8. SSH to DCC and verify files at the target path before deleting or moving the source staging copy.

Common transfer failures:

- Transfer exceeds a timeout window.
- Destination folder does not exist.
- User lacks write permission.
- Transfer was cancelled.
- Quota or purge policy makes the chosen destination wrong.

## Slurm Partition Selection

Verify exact partition names on the live DCC system:

```bash
sinfo
sinfo -o "%P %D %t %G %m %c"
```

The source runbook mentions GPU common/scavenger access and CPU common/scavenger access, but also contains both `gpu-scavenger`-style prose and `scavenger-gpu`-style example commands. Official pages may also mix example names such as `gpu-common` and table names such as `common-gpu`. Treat this as a reason to verify current partition names with `sinfo` and `scontrol` before writing final commands.

For specific GPU resource strings:

```bash
scontrol show node "$(sinfo -h -r -p PARTITION -o %N | head -n 1)" | grep Gres
```

Use scavenger/preemptible partitions only when the workload can tolerate interruption. Long scavenger jobs must checkpoint at least hourly or at a cadence justified by the cost of lost work.

## Interactive Debugging

Use interactive sessions for quick debugging, smoke tests, environment checks, and short commands that need live output:

```bash
srun \
  --partition=PARTITION \
  --account=ACCOUNT \
  --cpus-per-task=16 \
  --mem=64G \
  --gres=GPU_GRES \
  --time=02:00:00 \
  --pty bash -i
```

Example adapted from the source runbook, after verifying names:

```bash
srun -p scavenger-gpu -c 16 --mem=64G --gres=gpu:6000_ada:1 --pty bash -i
```

Notes:

- More resources generally mean longer queue waits.
- Closing the shell or disconnecting can end the session.
- Do not use interactive sessions for long training or unattended runs.
- Use smaller/common resources for lightweight tests; do not request high-VRAM GPUs unless needed.

Inside an allocated GPU session, verify the GPU before running project work:

```bash
hostname
nvidia-smi
```

## Batch Jobs

Use batch jobs for long runs, training, sweeps, and unattended work.

Minimal template:

```bash
#!/usr/bin/env bash
#SBATCH --job-name=PROJECT-RUN_NAME
#SBATCH --partition=PARTITION
#SBATCH --account=ACCOUNT
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --gres=GPU_GRES
#SBATCH --time=WALLTIME
#SBATCH --output=/work/NETID/PROJECT/logs/%x-%j.out
#SBATCH --error=/work/NETID/PROJECT/logs/%x-%j.err

set -euo pipefail

echo "host=$(hostname)"
echo "job_id=${SLURM_JOB_ID:-unknown}"
echo "partition=${SLURM_JOB_PARTITION:-unknown}"
echo "workdir=$(pwd)"
date

# Load modules or activate the project environment according to the repo.
# Run the project command here with explicit data, output, cache, and checkpoint paths.

date
```

Submit:

```bash
mkdir -p /work/NETID/PROJECT/logs
sbatch path/to/job.sh
```

Alternatively pass resource flags at submission time:

```bash
sbatch \
  --partition=PARTITION \
  --account=ACCOUNT \
  --cpus-per-task=16 \
  --mem=64G \
  --gres=GPU_GRES \
  --time=WALLTIME \
  path/to/job.sh
```

Monitor:

```bash
squeue -u "$USER"
squeue -j JOB_ID
tail -f /work/NETID/PROJECT/logs/PROJECT-RUN_NAME-JOB_ID.out
sacct -j JOB_ID --format=JobID,JobName,State,Elapsed,MaxRSS,ExitCode
```

Cancel:

```bash
scancel JOB_ID
```

## Jupyter / DCC OnDemand

Use DCC OnDemand when the user's actual workflow needs notebooks:

1. Open `https://dcc-ondemand-01.oit.duke.edu/`.
2. Select Jupyter.
3. Show advanced customization fields.
4. Select the correct Slurm account if applicable. For Romero lab work, this may be `romerolab`, but verify it first.
5. Choose partition, cores, RAM, and GPU.
6. Launch and wait for the allocation.
7. Navigate to `/work/NETID` or the project path from the file explorer.

Do not convert a script workflow into notebooks just because OnDemand exists.

## Project AGENTS.md Pattern

When adding DCC instructions to a repo `AGENTS.md`, keep it short and operational:

- Source-of-truth repo path on DCC.
- Stable environment path and activation command.
- Data/cache/output paths.
- Exact smoke-test command.
- Exact Slurm interactive command if the repo needs one.
- Exact `sbatch` template or script path for long runs.
- Known DCC hazards for this repo.

Avoid adding generic contacts, broad DCC background, or stale Coltrane repair context unless the user explicitly asks for that.

## Troubleshooting

- `Permission denied` on lab paths: verify group membership and path ownership before changing commands.
- Job remains pending: inspect `squeue -j JOB_ID`; reduce requested GPU/memory/time or choose a less constrained verified partition.
- Scavenger job is cancelled/requeued: treat as expected preemption; add or tighten checkpointing.
- Interactive work dies after disconnect: rerun as `sbatch`.
- No GPU visible: confirm the job actually requested a GPU and run `nvidia-smi` inside the allocation.
- Transfer failed: check timeout, permission, quota, cancellation, and whether the destination folder existed.
- `/work` files disappear or are at risk: move durable data to persistent or archive storage; do not treat scratch as backup.
- Environment setup fails with stale file handle or unstable filesystem errors: recreate env on persistent group/home storage and keep caches/temp dirs on `/work`.
