# Build a Multi-Cluster Kubernetes Rollout Pipeline with PipeCD

Pre-DevFest Ibadan 2026 · Cloud Session · Saturday 31 October 2026

You will write a rollout pipeline for one app that runs on **two Kubernetes clusters at once**, then check exactly what it will do before anything is deployed. You don't need to install Kubernetes. The facilitator runs the clusters; you write the config.

## Before you arrive (5 minutes)

- [ ] A laptop with a browser
- [ ] A GitHub account, signed in on that laptop
- [ ] That's it. No Docker, no Kubernetes, no installs. You'll edit files in the GitHub web editor.

## How the workshop works

```
 you                         GitHub                         facilitator's laptop
 ───                         ──────                         ────────────────────
 fork the repo   ───────►   your fork
 edit app.pipecd.yaml
 open a pull request ────►  PR on the workshop repo  ───►  PipeCD runs "plan preview"
                                                           on your change, against
 read the result  ◄──────   comment on your PR       ◄───  cluster1 and cluster2
```

Plan preview answers: *if this change were merged, what would PipeCD do?* Which strategy it would use (a quick sync or your pipeline) and which Kubernetes resources would change on each cluster. Nothing gets deployed by a preview.

At the end, we merge a few pull requests live and watch them roll out to both clusters.

## Setup (in the room)

1. Open the workshop repo link from the slides and click **Fork**.
2. In your fork, open `app/hello-ibadan/`. You'll only edit files in this folder.
3. Have a look at the three files:
   - `deployment.yaml` and `service.yaml`: a normal Kubernetes app
   - `app.pipecd.yaml`: tells PipeCD how to deploy it. No pipeline yet.

## Exercise 1: Change the version, no pipeline (5 min)

In `deployment.yaml`, change the image tag from `v0.47.0` to `v0.47.1`.

Commit to a new branch in your fork and open a pull request against the workshop repo's `main`. Put your name in the PR title, like `Ex1 – Adaeze`.

**What to expect in the preview comment:** `QUICK_SYNC`. With no pipeline, PipeCD applies the change to every cluster at once.

**Think:** Is that safe if the new version is broken?

## Exercise 2: A canary pipeline on both clusters (15 min)

Add a `pipeline` block to `app.pipecd.yaml`, under `spec:`, with four stages in this order:

| Stage | What it does |
|---|---|
| `K8S_MULTI_CANARY_ROLLOUT` | Starts a few pods of the new version next to the old ones. Set `replicas: 1`. |
| `WAIT` | Pauses. Set `duration: 30s`. |
| `K8S_MULTI_PRIMARY_ROLLOUT` | Makes the new version the main one |
| `K8S_MULTI_CANARY_CLEAN` | Removes the canary pods |

The shape looks like this:

```yaml
spec:
  pipeline:
    stages:
      - name: STAGE_NAME
        with:
          option: value
```

Keep your image change from Exercise 1 so there's something to roll out. Push to your PR. The preview runs again.

**What to expect:** `PIPELINE_SYNC`. Every stage runs on **both** clusters in parallel.

## Exercise 3: One cluster first (15 min)

Real teams don't upgrade every region at once. Change your pipeline so that:

1. The canary runs on `cluster1` only
2. All of `cluster1`'s traffic goes to the canary
3. After the wait, the new version is promoted on **both** clusters
4. `cluster1`'s traffic goes back to the primary, and its canary is cleaned up

You need two new things:

- `multiTargets: [cluster1]` under a stage's `with:` limits that stage to one cluster
- The `K8S_MULTI_TRAFFIC_ROUTING` stage with `all: canary` or `all: primary`

**Think:** Why does traffic have to be all-or-nothing here? (Hint: look up the `podselector` and `istio` traffic routing methods.)

## Exercise 4: Watch a rollback (demo)

The facilitator merges a change with a broken image tag, then cancels the deployment with rollback. Watch PipeCD run `K8S_MULTI_ROLLBACK` and restore **both** clusters to the last good version.

## Stuck?

- Indentation matters in YAML: use spaces, not tabs
- Compare with `solutions/` in the repo, after you've tried
- Raise your hand. Helpers are walking around.

## Take it home

- PipeCD: https://pipecd.dev
- The multi-cluster plugin docs: https://pipecd.dev/docs-v1.0.x/plugins/official/kubernetes-multicluster/
- Contribute: https://github.com/pipe-cd/pipecd and say hi in `#pipecd` on the CNCF Slack
