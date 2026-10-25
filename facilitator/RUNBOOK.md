# Facilitator runbook

Attendees run PipeCD and two clusters on their own laptops. Anyone who can't uses the no-install way: they open a PR, and your PipeCD comments a preview.

## What the test on 25 Oct showed

- **Versions must match:** control plane `ghcr.io/pipe-cd/pipecd:v0.57.0-73-g5b41282`, with piped, pipectl and plugins built from the same commit (`5b41282`). Newer piped gets stuck at PENDING.
- **PipeCD's quickstart MinIO image is gone** (pipe-cd/pipecd#7380). `setup.sh` uses Chainguard's instead.
- **`service.yaml` needs `pipecd.dev/variant: primary`**, or traffic routing fails.
- **Downloads:** about 1.2 GB per laptop. Memory: about 1.9 GB.
- Without a check (`ANALYSIS`) step, a broken update still says SUCCESS. Use a 2-minute wait for the undo exercise.

## Before the day

1. On good internet, run `./facilitator/build-tools.sh`. It publishes the `tools` release that `setup.sh` downloads. **The setup won't work for attendees without it.**
2. Record your screen doing Exercises 2–4, as a backup.

## On the day

1. **First thing:** show the repo link and say "fork, clone, run `./scripts/setup.sh` now". Then do your intro while it downloads.
2. Your own laptop: start OrbStack, then `kubectl --context kind-cluster1 -n pipecd port-forward svc/pipecd 8080 &` and `./scripts/piped.sh`.
3. Walk around and help with setup.
4. For people on the no-install way, run `./facilitator/preview-prs.sh` every few minutes.
5. Do each exercise on the projector after the room has tried it.

## Things to say

- The multi-cluster plugin is **alpha**.
- Without Istio, users can only go to one version at a time.

## If something breaks

| Problem | Fix |
|---|---|
| No Docker, or slow download | No-install way, or pair with a neighbour |
| Setup stuck at "waiting for it to start" | Still downloading. Check with `kubectl --context kind-cluster1 get pods -n pipecd` |
| `piped.sh` can't connect | Run `./scripts/setup.sh` again (it restarts the connection) |
| Deployment stuck at PENDING | Wrong piped version. Delete `~/.pipecd-workshop/bin/piped` and run `setup.sh` again |
| App missing under suggestions | Wait a minute. piped reads your fork's `main` every 30 seconds |
