# Build a Multi-Cluster Kubernetes Rollout Pipeline with PipeCD

Pre-DevFest Ibadan 2026 · Cloud Session · Saturday 31 October 2026

You'll run PipeCD and **two Kubernetes clusters on your own laptop**, write a rollout pipeline for one app, preview exactly what it will do on each cluster, then roll it out and roll it back.

## Pick your track

| | Track A: run it yourself | Track B: no-install |
|---|---|---|
| You need | Docker running, 8 GB RAM (16 GB is comfortable), 10 GB free disk, git | A browser and a GitHub account |
| You get | Your own control plane, piped and two clusters. You deploy and roll back yourself. | You write the same pipelines. The facilitator's PipeCD previews them and comments on your PR. |
| Works on | macOS, Linux, Windows **with WSL2** | Anything |

Not sure? Start on Track A. If setup fails or your laptop struggles, switch to Track B or pair with a neighbour. The exercises are the same.

---

## Track A setup (15–20 min, mostly waiting)

Do this while the intro talk is on.

**Windows:** do every step inside your WSL2 Ubuntu terminal, with Docker Desktop's WSL integration turned on.

1. **Fork and clone.** Fork the workshop repo on GitHub, then:
   ```sh
   git clone https://github.com/<you>/pipecd-multicluster-workshop.git
   cd pipecd-multicluster-workshop
   ```
   Make sure you can push to your fork. `gh auth login` is the easiest way.

2. **Install the tools.** Grab a USB stick from the front, copy the `pipecd-bundle` folder somewhere, then:
   ```sh
   ./scripts/install-tools.sh /path/to/pipecd-bundle
   export PATH="$HOME/.pipecd-workshop/bin:$PATH"
   ```
   No USB stick? Leave off the path: `./scripts/install-tools.sh` downloads them instead.

3. **Start the clusters and PipeCD.** Takes about 5–10 minutes:
   ```sh
   ./scripts/up.sh /path/to/pipecd-bundle
   ```

4. **Log in.** Open http://localhost:8080?project=quickstart. User and password are both `hello-pipecd`.

5. **Register piped.** In the console: **Settings → Piped → + ADD**, name it `my-piped`, Save. Copy the **Piped Id** and the **Base64 Encoded Piped Key**. In a **new terminal tab**, from the repo folder:
   ```sh
   ./scripts/run-piped.sh <PIPED_ID> <BASE64_PIPED_KEY>
   ```
   Leave it running.

6. **Register the app.** **Applications → + ADD → PIPED V1 ADD FROM SUGGESTIONS**. Pick `my-piped`, tick **both** `cluster1` and `cluster2`, pick `hello-ibadan`, Save. PipeCD deploys it to both clusters straight away.
   ```sh
   ./scripts/status.sh    # 2 primary pods on v0.47.0 in each cluster
   ```

7. **Create an API key** for plan preview: **Settings → API Key → + ADD**, role `READ_WRITE`. Copy it, then:
   ```sh
   echo '<the key>' > ~/.pipecd-workshop/api-key
   ```

**How you'll work on Track A:**

```sh
git switch -c ex1              # a branch per exercise
# edit files in app/hello-ibadan/
git commit -am "ex1"
./scripts/preview.sh           # pushes the branch, asks PipeCD what it would do
git switch main && git merge ex1 && git push   # deploy it for real
watch -n2 ./scripts/status.sh  # watch both clusters (no `watch`? just re-run it)
```

## Track B setup (2 min)

1. Fork the workshop repo on GitHub.
2. You'll edit files in `app/hello-ibadan/` with GitHub's web editor (press `.` on your fork to open it).
3. For each exercise, commit to a new branch in your fork and **open a pull request against the workshop repo's `main`**. Put your name and the exercise in the title, like `Ex2 – Adaeze`. A plan preview from the facilitator's PipeCD appears as a comment within a minute or two.

---

## The app

`app/hello-ibadan/` holds a normal Kubernetes Deployment and Service, plus `app.pipecd.yaml`, which tells PipeCD how to deploy it. You'll only edit files in this folder.

## Exercise 1: Change the version, no pipeline (5 min)

In `deployment.yaml`, change the image tag from `v0.47.0` to `v0.47.1`. Preview it (Track A: `./scripts/preview.sh`; Track B: open your PR).

**Expect:** `QUICK_SYNC`. With no pipeline, PipeCD applies the change to every cluster at once.

**Track A:** merge it to your `main`, push, and watch `status.sh`. Both clusters switch together.

**Think:** Is that safe if the new version is broken?

## Exercise 2: A canary pipeline on both clusters (15 min)

Change the image to `v0.47.2`. Then add a `pipeline` block to `app.pipecd.yaml`, under `spec:`, with four stages in this order:

| Stage | What it does |
|---|---|
| `K8S_MULTI_CANARY_ROLLOUT` | Starts new-version pods next to the old ones. Set `replicas: 1`. |
| `WAIT` | Pauses. Set `duration: 30s`. |
| `K8S_MULTI_PRIMARY_ROLLOUT` | Makes the new version the main one |
| `K8S_MULTI_CANARY_CLEAN` | Removes the canary pods |

The shape:

```yaml
spec:
  pipeline:
    stages:
      - name: STAGE_NAME
        with:
          option: value
```

**Expect:** `PIPELINE_SYNC`. Every stage runs on **both** clusters in parallel.

**Track A:** merge and watch it in the console's deployment view next to `status.sh`. During `WAIT` you'll see a `canary` pod in each cluster.

## Exercise 3: One cluster first (15 min)

Real teams don't upgrade every region at once. Bump the image back to `v0.47.1`, then change your pipeline so that:

1. The canary runs on `cluster1` only
2. All of `cluster1`'s traffic goes to the canary
3. After the wait, the new version is promoted on **both** clusters
4. `cluster1`'s traffic goes back to the primary, and its canary is cleaned up

You need two new things:

- `multiTargets: [cluster1]` under a stage's `with:` limits that stage to one cluster
- The `K8S_MULTI_TRAFFIC_ROUTING` stage with `all: canary` or `all: primary`

**Track A:** during the wait, run `status.sh`. `cluster1`'s service points at `canary`; `cluster2` hasn't changed.

**Think:** Why does traffic have to be all-or-nothing here? Look up the `podselector` and `istio` traffic routing methods.

## Exercise 4: Roll back (Track A hands-on, Track B watch the screen)

Change the image to `v9.9.9`, a version that doesn't exist, and deploy it with your Exercise 2 pipeline. While it's in the `WAIT` stage, open the deployment in the console and click **Cancel**, choosing to roll back. PipeCD runs `K8S_MULTI_ROLLBACK` and restores **both** clusters to the last good version.

## Stuck?

- YAML indentation: spaces, not tabs
- Compare with `solutions/`, after you've tried
- piped logs are in the terminal where `run-piped.sh` is running
- Raise your hand

## Afterwards

- `./scripts/down.sh` deletes the clusters and frees the memory
- PipeCD: https://pipecd.dev
- Multi-cluster plugin docs: https://pipecd.dev/docs-v1.0.x/plugins/official/kubernetes-multicluster/
- Contribute: https://github.com/pipe-cd/pipecd, and say hi in `#pipecd` on the CNCF Slack
