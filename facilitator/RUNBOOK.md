# Facilitator runbook

Pre-DevFest Ibadan 2026 · Cloud Session · Sat 31 Oct 2026

Everything runs on your laptop: three kind clusters (`pipecd` for the control plane, `cluster1` and `cluster2` as deploy targets), piped v1 from source, and a script that previews attendees' PRs. Attendees only need a browser and a GitHub account.

## What's verified and what isn't

Checked against pipe-cd/pipecd on 24 Oct 2026:

- `kubernetes_multicluster` plugin v0.1.0 released 9 Sep 2026. **Alpha.** Say so on stage.
- Plan preview for the plugin: #6685 (26 May 2026) and #7437 (11 Oct 2026). The pipedv1 plan preview handler is wired in `pkg/app/pipedv1/cmd/piped/piped.go`.
- The latest *released* pipedv1 image is `pipedv1-exp:v1.0.0-alpha1` (Oct 2025), older than the plan preview work. That's why piped runs from master here.
- PodSelector traffic routing is all-or-nothing (100% to one variant). Percentages need Istio. The exercises use `all: canary` / `all: primary` only.
- `spec.planner.autoRollback` defaults to `true`.

**Not verified yet, which is what the rehearsal is for:** the whole flow end to end on this laptop. In particular, plan preview output for a fork PR mirrored to `preview/pr-N`, and the control plane image `v0.58.0` working with piped from master.

## 1. One-time setup (do this by Tue 27 Oct)

```sh
# a. A clean checkout of upstream master, separate from your working clone
git clone https://github.com/pipe-cd/pipecd.git ~/Desktop/Git-projects/pipecd-master

# b. Start OrbStack, then:
cd ~/Desktop/Git-projects/pipecd-multicluster-workshop
./facilitator/setup.sh

# c. Leave this running in its own terminal tab
./facilitator/port-forward.sh
```

d. Open http://localhost:8080?project=quickstart and log in as `hello-pipecd` / `hello-pipecd`.

e. **Settings > Piped > +ADD** → name it `workshop` → copy the piped ID and the **Base64 encoded** key:

```sh
./facilitator/run-piped.sh <PIPED_ID> <BASE64_PIPED_KEY>   # own terminal tab; later runs need no args
```

f. **Applications > +ADD > PIPED v1 ADD FROM SUGGESTIONS** → piped `workshop` → tick **both** `cluster1` and `cluster2` → pick `hello-ibadan` → Save. The first deployment is a quick sync to both clusters.

g. **Settings > API Key > +ADD**, role `READ_WRITE`:

```sh
pbpaste > facilitator/.work/api-key    # after copying the key
```

h. Check: `./facilitator/status.sh` shows 2 `primary` pods on `v0.47.0` in each cluster.

## 2. Rehearsal (do it twice, the second time on a phone hotspot)

1. From a **second GitHub account** (or ask a friend), fork the repo and open a PR for Exercise 1.
2. `./facilitator/preview-prs.sh`. A comment should appear on the PR saying `QUICK_SYNC`.
3. Push the Exercise 2 solution to that PR and run it again. Expect `PIPELINE_SYNC`.
4. Merge the Exercise 3 solution on `main`. Watch it in the UI and in `watch -n2 ./facilitator/status.sh`: canary on cluster1 only, then promoted on both.
5. Exercise 4 rollback: change the image to `ghcr.io/pipe-cd/helloworld:v0.47.2`, then to a tag that doesn't exist (e.g. `v9.9.9`). During the `WAIT` stage, click **Cancel** with rollback. Expect `K8S_MULTI_ROLLBACK` on both clusters.
6. **Record your screen** for steps 4–5. That's the fallback if anything breaks on the day.
7. Time how long a preview takes per PR. 30 PRs at that rate tells you whether one script can keep up.

Write down anything that didn't match this runbook. Fix it here before Saturday.

## 3. On the day

**T-60 min:** start OrbStack, `port-forward.sh`, `run-piped.sh`. Reset `main` to the starting state (no pipeline, `v0.47.0`) and let it quick-sync. Check `status.sh`. Put the repo link and a QR code on a slide.

**During exercises:** run `./facilitator/preview-prs.sh --watch` in a visible terminal. Previews land as PR comments within about a minute.

**Live merges:** pick 1–2 good PRs, merge them, show the UI pipeline view next to `status.sh`.

**After:** `./facilitator/teardown.sh` deletes the `preview/*` branches. Add `--clusters` to delete the kind clusters.

## Timings

The organisers haven't confirmed the slot length yet.

| | 60 min | 90 min |
|---|---|---|
| Intro: PipeCD, plugins, why multi-cluster | 8 | 12 |
| Setup: fork, tour the files | 5 | 8 |
| Ex 1: version bump → `QUICK_SYNC` | 5 | 8 |
| Ex 2: canary on both clusters | 15 | 20 |
| Ex 3: one cluster first | 12 | 20 |
| Ex 4: live merge + rollback demo | 8 | 10 |
| Wrap-up, how to contribute, Q&A | 7 | 12 |

At 60 minutes, make Ex 3 a walkthrough of the solution instead of a hands-on exercise if the room is slow.

## If something breaks

| Problem | Do this |
|---|---|
| Venue Wi-Fi down | Phone hotspot for your laptop. Attendees pair up on whoever has data. Images are pre-loaded into the clusters. |
| Previews slow or stuck | Keep going. Review 3–4 PRs by eye on screen, then run the preview on one live. |
| piped crashes | Restart `run-piped.sh`. It keeps its config. |
| Everything is down | Play the recording from the rehearsal and walk through `solutions/`. |
| An attendee can't fork | Pair them with a neighbour. |
