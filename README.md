# PipeCD multi-cluster workshop

**Build a Multi-Cluster Kubernetes Rollout Pipeline with PipeCD**
Pre-DevFest Ibadan 2026 · Cloud Session · Saturday 31 October 2026

Run PipeCD and two Kubernetes clusters on your laptop. Write one rollout pipeline, preview exactly what it will do on each cluster, then roll it out and roll it back.

**Attendees:** start with [docs/ATTENDEE-GUIDE.md](docs/ATTENDEE-GUIDE.md).

- **Track A (run it yourself):** Docker, 8 GB RAM, macOS / Linux / Windows with WSL2
- **Track B (no install):** a browser and a GitHub account

**Facilitator:** [facilitator/RUNBOOK.md](facilitator/RUNBOOK.md).

## What's in here

| Path | What it is |
|---|---|
| `app/hello-ibadan/` | The app you edit: a Deployment, a Service and `app.pipecd.yaml` |
| `docs/ATTENDEE-GUIDE.md` | Setup and the four exercises |
| `scripts/` | `install-tools.sh`, `up.sh`, `run-piped.sh`, `preview.sh`, `status.sh`, `down.sh` |
| `solutions/` | Reference answers. Try first. |
| `facilitator/` | Building the binaries and the USB offline bundle, and Track B PR previews |

## Notes

- piped v1 and the plugins are built from `pipe-cd/pipecd` master, because the latest released pipedv1 build predates the multi-cluster plugin's plan preview.
- The `kubernetes_multicluster` plugin is in alpha. Its configuration may change.

## Links

- PipeCD: https://pipecd.dev
- Multi-cluster plugin docs: https://pipecd.dev/docs-v1.0.x/plugins/official/kubernetes-multicluster/
- Source: https://github.com/pipe-cd/pipecd
