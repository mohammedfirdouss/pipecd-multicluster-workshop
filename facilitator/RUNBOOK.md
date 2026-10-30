# Facilitator runbook

Attendees run PipeCD and two clusters on their own laptops. Anyone who can't uses the no-install way: they open a PR, and your PipeCD comments a preview.

## What the test on 25 Oct showed

- **Versions must match:** control plane `ghcr.io/pipe-cd/pipecd:v0.57.0-73-g5b41282`, with piped, pipectl and plugins built from the same commit (`5b41282`). piped built from newer code (for example master) leaves deployments stuck at PENDING.
- **PipeCD's quickstart MinIO image is gone** (pipe-cd/pipecd#7380). `setup.sh` uses Chainguard's instead.
- **`service.yaml` needs `pipecd.dev/variant: primary`**, or traffic routing fails.
- **Downloads:** about 1.2 GB per laptop. Memory: about 1.9 GB.
- Without a check (`ANALYSIS`) step, a broken update still says SUCCESS. Use a 2-minute wait for the undo exercise.

## Before the day

1. On good internet, run `./facilitator/build-tools.sh`. It publishes the `tools` release that `setup.sh` downloads. **The setup won't work for attendees without it.**
2. Record your screen doing Exercises 2–4, as a backup.

## On the day

Before attendees arrive: start OrbStack and stop anything else using port 8080. Then run `kubectl --context kind-cluster1 -n pipecd port-forward svc/pipecd 8080 &` and `./scripts/piped.sh` (no arguments: it reuses the saved config). Open the PipeCD console and this repo on the projector.

No slides needed. The setup download can take 30+ minutes on slow internet, so the first half is you showing things on your screen while it runs. Times assume a 90-minute slot; shrink the middle if yours is shorter.

| Time | What you do | What attendees do |
|---|---|---|
| 0–5 min | Put the repo link on screen. "Fork, clone, start Docker, run `./scripts/setup.sh` now." | Start the setup |
| 5–15 min | Talk with the repo open: what PipeCD is, piped vs the control plane, why two clusters. Walk through `app/hello-ibadan/` | Setup runs |
| 15–35 min | Live on your laptop: Exercise 1 (preview, then deploy), then Exercise 2 (canary). Show the Deployments page and `status.sh` | Watch. Anyone without Docker starts the no-install way |
| 35–45 min | Walk around. Help people whose setup finished connect piped and add the app | Steps 2–5 of the guide |
| 45–80 min | Exercises 1–4. Run `./facilitator/preview-prs.sh` every few minutes for no-install PRs | Exercises, on their laptop or the no-install way |
| 80–90 min | Recap, questions, `cleanup.sh` | |

Rules of thumb:
- Anyone still waiting at minute 45 does the no-install way and switches to their laptop when setup says **Done**.
- Do each exercise on the projector after the room has tried it.

## Things to say

- The multi-cluster plugin is **alpha**.
- Without Istio, users can only go to one version at a time.

## If something breaks

| Problem | Fix |
|---|---|
| No Docker, or slow download | No-install way, or pair with a neighbour |
| Setup stuck at "downloading and starting it" | Still downloading. Check with `kubectl --context kind-cluster1 get pods -n pipecd`. After 45 minutes it stops; run `setup.sh` again, it keeps what it downloaded |
| "Docker isn't running" | Open Docker Desktop or OrbStack first |
| "toomanyrequests" or rate limit | Docker Hub limits downloads per internet address. Switch to a hotspot, or `docker login` with a free Docker account |
| `piped.sh` can't connect | Check nothing else uses port 8080 (`lsof -i :8080`), then run `./scripts/setup.sh` again (it restarts the port-forward) |
| Deployment stuck at PENDING | Wrong piped version. Delete `~/.pipecd-workshop/bin/piped` and run `setup.sh` again |
| App missing under suggestions | Wait a minute. piped reads your fork's `main` every 30 seconds |
