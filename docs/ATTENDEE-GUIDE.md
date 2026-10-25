# Workshop guide

Today you'll update one app that runs on **two Kubernetes clusters**. First you check what will change. Then you watch it go live, one step at a time. Then you undo a bad update.

**You need:** a GitHub account and a browser. Nothing to install.

## How it works

1. You edit the app in **your own copy** of this repo (a fork).
2. You open a **pull request (PR)**.
3. PipeCD replies on your PR with a **preview**: what would change on each cluster. Nothing is deployed yet.
4. We pick a few PRs and deploy them live on the big screen.

## Setup (2 minutes)

1. Go to https://github.com/mohammedfirdouss/pipecd-multicluster-workshop and click **Fork**.
2. In your fork, press the `.` key. An editor opens in your browser.
3. Open the folder `app/hello-ibadan/`. You only edit files in here:
   - `deployment.yaml`: the app and its version
   - `service.yaml`: how traffic reaches the app
   - `app.pipecd.yaml`: how PipeCD should deploy it

**For each exercise:**
1. Make the change.
2. Save it to a **new branch**.
3. Open a PR to `mohammedfirdouss/pipecd-multicluster-workshop`, branch `main`. Title it with your name and the exercise, like `Ex2 – Adaeze`.
4. Wait a few minutes for PipeCD's comment. To try again, just add another commit to the same PR.

## Exercise 1: Change the version

In `deployment.yaml`, change `v0.47.0` to `v0.47.1`.

**You should see:** `QUICK_SYNC`. That means PipeCD will update **both clusters at once**.

Think: what if the new version is broken?

(Both clusters get the same files, so the preview shows the change once, under `cluster1`.)

## Exercise 2: Update slowly (canary)

A **canary** is a small test: run one copy of the new version first, wait, then update everything.

Keep your change from Exercise 1. In `app.pipecd.yaml`, add this under `spec:` and fill in the two `???`:

```yaml
  pipeline:
    stages:
      - name: K8S_MULTI_CANARY_ROLLOUT   # start 1 copy of the new version
        with:
          replicas: 1
      - name: WAIT                       # wait 30 seconds
        with:
          duration: 30s
      - name: ???                        # update everything to the new version
      - name: ???                        # remove the test copy
```

The two missing names are `K8S_MULTI_PRIMARY_ROLLOUT` and `K8S_MULTI_CANARY_CLEAN`. Which goes first?

**You should see:** `PIPELINE_SYNC`. Each step runs on **both** clusters.

## Exercise 3: One cluster first

Big teams don't update every region at once. Try the new version on **cluster1 only** first.

Add this inside the canary step, under `with:`:

```yaml
          multiTargets:
            - cluster1
```

Then add a step right after it, to send cluster1's users to the new version:

```yaml
      - name: K8S_MULTI_TRAFFIC_ROUTING
        with:
          all: canary
          multiTargets:
            - cluster1
```

Before the clean-up step, send them back with `all: primary`. The full answer is in `solutions/ex3-one-cluster-first.yaml`.

Why "all"? Without an extra tool like Istio, traffic can only go to one version at a time.

## Exercise 4: Undo a bad update (on the big screen)

We deploy a version that doesn't exist (`v9.9.9`), then click **Cancel with Rollback**. PipeCD puts **both** clusters back to the last good version.

Note: PipeCD only checks that the new version works if you add a check step (called `ANALYSIS`). Without it, a broken update can still say "success".

## Want to run it all on your laptop?

Try it at home with Docker and good internet: [RUN-IT-YOURSELF.md](RUN-IT-YOURSELF.md).

## Learn more

- PipeCD: https://pipecd.dev
- Contribute: https://github.com/pipe-cd/pipecd, and say hi in `#pipecd` on the CNCF Slack
