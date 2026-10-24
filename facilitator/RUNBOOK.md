# Facilitator runbook

## Before the day

1. `./facilitator/build-tools.sh` builds piped + plugins and publishes the `tools` release that `setup.sh` downloads. Re-run it if PipeCD master gets a fix you need.
2. Do the whole attendee guide yourself, every exercise.
3. Do it again on a second laptop if you can.
4. Record your screen doing exercises 2–4. That's your backup if the room's setup fails.

## On the day

- One hour before: start Docker, `./scripts/setup.sh`, `./scripts/piped.sh`. Reset `main` to the start (no pipeline, image `v0.47.0`).
- Start of session: show the repo link. Tell people to run `setup.sh` now, while you do the intro.
- During exercises: run `./facilitator/preview-prs.sh` every few minutes for the people without Docker.
- After: delete the `preview/pr-*` branches.

## Things to say

- The multi-cluster plugin is **alpha**.
- Without Istio, traffic routing is all-or-nothing (100% to one version).

## If something breaks

| Problem | Fix |
|---|---|
| No Docker, or not enough memory | Use the "Without Docker" path in the guide, or pair up |
| Control plane pods stuck `Pending` | Not enough memory. Close other apps, `cleanup.sh`, `setup.sh` again |
| `piped.sh` can't connect | `setup.sh` again (it restarts the console port-forward) |
| App missing from suggestions | piped watches the fork's `main`. Check the repo URL in piped's output |
| Everything is down | Play the recording |
