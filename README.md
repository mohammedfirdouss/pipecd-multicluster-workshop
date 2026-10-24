# PipeCD multi-cluster workshop

**Build a Multi-Cluster Kubernetes Rollout Pipeline with PipeCD**
Pre-DevFest Ibadan 2026 · Cloud Session · Saturday 31 October 2026

One app, two Kubernetes clusters, one rollout pipeline. You write the pipeline. PipeCD previews exactly what it would do on each cluster before anything is deployed.

**Attendees:** start with [docs/ATTENDEE-GUIDE.md](docs/ATTENDEE-GUIDE.md). You need a browser and a GitHub account. Nothing to install.

**Facilitator:** see [facilitator/RUNBOOK.md](facilitator/RUNBOOK.md).

## What's in here

| Path | What it is |
|---|---|
| `app/hello-ibadan/` | The app attendees edit: a Deployment, a Service and `app.pipecd.yaml` |
| `docs/ATTENDEE-GUIDE.md` | The exercises |
| `solutions/` | Reference answers. Try first. |
| `facilitator/` | Scripts to run the clusters, PipeCD and the PR previews |

## How it works

Attendees fork this repo and open pull requests that change `app/hello-ibadan/`. The facilitator's laptop runs a PipeCD control plane and a piped agent connected to two kind clusters. A script runs `pipectl plan-preview` on each PR and posts the result as a comment. Selected PRs are merged live and roll out to both clusters.

The `kubernetes_multicluster` plugin is in alpha. Its configuration may change.

## Links

- PipeCD: https://pipecd.dev
- Multi-cluster plugin docs: https://pipecd.dev/docs-v1.0.x/plugins/official/kubernetes-multicluster/
- Source: https://github.com/pipe-cd/pipecd
