# Facilitator runbook

Attendees edit in their forks and open PRs. Your laptop runs PipeCD and two kind clusters: it previews their PRs and does the live rollouts on the projector.

## Tested on 25 Oct 2026

Exercises 1–4, plan preview and PR comments all worked end to end on a Mac with OrbStack.

- **Versions must match.** Control plane `ghcr.io/pipe-cd/pipecd:v0.57.0-73-g5b41282`, with piped, pipectl and plugins built from that same commit (`5b41282`). piped from `master` leaves deployments stuck at PENDING (it needs server change #6727, which no published image has yet).
- **PipeCD's quickstart MinIO image is gone** from Docker Hub (pipe-cd/pipecd#7380). `setup.sh` swaps in `cgr.dev/chainguard/minio`.
- **The Service selector must include `pipecd.dev/variant: primary`**, or `K8S_MULTI_TRAFFIC_ROUTING` fails.
- **Memory:** about 1.9 GB for both clusters plus the control plane.
- **Downloads are the risk:** the control plane image took 33 minutes on home internet, and piped downloads kubectl + helm (105 MB). Have everything running before you travel.
- Without an analysis stage, a broken image still reports SUCCESS. Use a `2m` wait for the rollback demo, and click Cancel with Rollback early.

## Before the day

1. `./facilitator/build-tools.sh` builds piped, pipectl and the plugins for macOS and Linux and publishes the `tools` release that `scripts/setup.sh` downloads.
2. Your laptop is already set up. If you ever rebuild it: `./scripts/setup.sh`, then follow [RUN-IT-YOURSELF.md](../docs/RUN-IT-YOURSELF.md).
3. Record your screen doing Exercises 2–4 as a backup.

## On the day

1. Start OrbStack. Check `kubectl get pods -n pipecd --context kind-cluster1` is all Running.
2. `kubectl --context kind-cluster1 -n pipecd port-forward svc/pipecd 8080 &`, then `./scripts/piped.sh` (no arguments).
3. Check `main` is at the start (image `v0.47.0`, no pipeline) and `./scripts/status.sh` shows v0.47.0 on both clusters.
4. During the exercises, run `./facilitator/preview-prs.sh` every few minutes.
5. Live: merge a good PR for each exercise, and show the deployment page next to `watch ./scripts/status.sh`.
6. After: reset `main` and delete the `preview/pr-*` branches.

## Things to say

- The multi-cluster plugin is **alpha**.
- Without Istio, traffic routing is all-or-nothing.
- Plan preview shows one diff when every cluster gets the same files.

## If something breaks

| Problem | Fix |
|---|---|
| Preview comment says it failed | Usually YAML indentation. Show them the error. |
| `piped.sh` can't connect | Restart the port-forward (step 2) |
| Deployment stuck at PENDING | piped and control plane versions don't match. See above. |
| Everything is down | Play the recording |
