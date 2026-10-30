# PipeCD multi-cluster workshop

**Build a Multi-Cluster Kubernetes Rollout Pipeline with PipeCD**. Pre-DevFest Ibadan 2026, Cloud Session, Saturday 31 October 2026.

You run PipeCD and two kind clusters on your laptop, deploy one app to both clusters, and work through four exercises: plan preview, canary rollout, one cluster first, and rollback.

**Start here: [docs/ATTENDEE-GUIDE.md](docs/ATTENDEE-GUIDE.md).** Run `./scripts/setup.sh` first. The first run downloads about 1.2 GB.

| Folder | What's in it |
|---|---|
| `app/hello-ibadan/` | The app you edit in the exercises |
| `scripts/` | `setup.sh`, `piped.sh`, `preview.sh`, `status.sh`, `cleanup.sh` |
| `solutions/` | Answers to Exercises 2 and 3 |
| `facilitator/` | Runbook and scripts for the workshop host |

Tested end to end on macOS (Apple Silicon) with OrbStack on 25 October 2026. On Windows, run everything inside WSL2.

The `kubernetes_multicluster` plugin is in alpha.
