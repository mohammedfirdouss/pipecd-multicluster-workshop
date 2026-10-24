# Facilitator runbook

Pre-DevFest Ibadan 2026 · Cloud Session · Sat 31 Oct 2026

**Format:** attendees run PipeCD and two kind clusters on their own laptops (Track A). Anyone who can't uses Track B: they open PRs, and your PipeCD previews them. You run the exact same scripts on your Mac for the projector and for Track B.

Nothing can be sent to attendees before the day, so venue Wi-Fi is the main risk. The **USB offline bundle** carries every binary and container image, so Track A laptops only need the internet for GitHub (fork, clone, push) and piped's one-time kubectl download.

## What's verified and what isn't

Checked against pipe-cd/pipecd on 24 Oct 2026:

- `kubernetes_multicluster` plugin v0.1.0 released 9 Sep 2026. **Alpha.** Say so on stage.
- Plan preview for the plugin: #6685 (26 May 2026), #7437 (11 Oct 2026). The pipedv1 plan preview handler is wired in `pkg/app/pipedv1/cmd/piped/piped.go`.
- The latest *released* pipedv1 image is `pipedv1-exp:v1.0.0-alpha1` (Oct 2025), older than the plan preview work. So piped and the plugins are built from master (`facilitator/build-tools.sh`).
- PodSelector traffic routing is all-or-nothing. Percentages need Istio. The exercises use `all: canary` / `all: primary` only.
- `spec.planner.autoRollback` defaults to `true`.
- The quickstart control plane images use `imagePullPolicy: IfNotPresent`, so images loaded from the bundle are used without pulling.

**Not verified until you rehearse:** the whole flow end to end. In particular: control plane `v0.58.0` with piped from master; plan preview output; `kind load image-archive` from the bundle; whether piped's kubectl download (tool registry) works on venue Wi-Fi; and real memory use on an 8 GB laptop.

## 1. Build (by Mon 26 Oct)

```sh
cd ~/Desktop/Git-projects/pipecd-multicluster-workshop

# a. Binaries for macOS + Linux, amd64 + arm64 (Windows = Linux build inside WSL2)
./facilitator/build-tools.sh            # check dist/, then:
./facilitator/build-tools.sh --release  # publishes them so ./scripts/install-tools.sh can download

# b. Your own setup (start OrbStack first)
./scripts/install-tools.sh              # downloads from the release you just published
export PATH="$HOME/.pipecd-workshop/bin:$PATH"
./scripts/up.sh
```

Then do the Track A setup from `docs/ATTENDEE-GUIDE.md` (piped, app, API key) on your own machine. The repo piped watches is **your** repo, which is also the Track B target.

```sh
# c. USB bundle (several GB, about 2× because it holds amd64 + arm64 images)
./facilitator/make-offline-bundle.sh /Volumes/<USB>/pipecd-bundle
```

Copy it to 4–6 USB sticks. Also put it on your laptop to AirDrop to Mac users.

## 2. Rehearse (by Tue 27 Oct, twice)

1. **Fresh machine test:** on a second laptop (or a fresh macOS user account), follow Track A from the USB bundle with **Wi-Fi off** except for GitHub. Time it and note every snag.
2. If you can, test one Windows + WSL2 laptop and one 8 GB laptop.
3. Run every exercise on Track A, including the Ex 4 rollback.
4. **Track B:** from a second GitHub account, open a PR against your repo, run `./facilitator/preview-prs.sh`, and check the comment.
5. **Record your screen** for Ex 2–4. That's the fallback if the room's setup fails.

Fix this runbook and the guide wherever reality differed.

## 3. On the day

**T-60 min:** OrbStack, `./scripts/up.sh`, `./scripts/run-piped.sh` (no args after the first run). Reset your repo's `main` to the starting state (no pipeline, `v0.47.0`) and let it quick-sync. `./scripts/status.sh`.

**Start of session:** show the repo link + QR. Hand out USB sticks. Say: "Start Track A setup now, it runs while I talk."

**During exercises:** keep `./facilitator/preview-prs.sh --watch` running for Track B. Walk the room for Track A setup problems.

**Live demo:** do each exercise on your own machine on the projector after the room has tried it.

**After:** delete the Track B preview branches:

```sh
git ls-remote --heads origin 'preview/*' | awk '{print $2}' | sed 's#refs/heads/##' | xargs -n1 git push origin --delete
```

## Timings (slot length not confirmed yet)

| | 60 min | 90 min |
|---|---|---|
| Intro while Track A installs: PipeCD, plugins, why multi-cluster | 10 | 15 |
| Finish setup: piped, app, API key | 8 | 12 |
| Ex 1: version bump → `QUICK_SYNC` | 5 | 8 |
| Ex 2: canary on both clusters | 15 | 20 |
| Ex 3: one cluster first | 10 | 15 |
| Ex 4: rollback | 5 | 8 |
| Wrap-up: the two real bugs, the LFX path, how to contribute | 7 | 12 |

At 60 minutes, demo Ex 3 on the projector instead of running it hands-on.

## If something breaks

| Problem | Do this |
|---|---|
| Laptop has no Docker, or under 8 GB RAM | Track B, or pair with a neighbour |
| Docker install needed on the day | Don't. Docker Desktop is a large download. Track B. |
| Control plane pods stuck `Pending` | Low memory. `./scripts/down.sh`, close other apps, retry; else Track B |
| `run-piped.sh` can't connect | Is `up.sh`'s port-forward alive? `curl localhost:8080`. Re-run `up.sh`. |
| App not in "suggestions" | piped is watching the fork's `main`. Check the fork URL in the piped logs. |
| Previews slow or stuck (Track B) | Review a few PRs by eye on screen and preview one live |
| Everything down | Play the rehearsal recording and walk through `solutions/` |
