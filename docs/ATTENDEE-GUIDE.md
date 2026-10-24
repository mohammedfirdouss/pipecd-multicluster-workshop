# Workshop guide

You'll run PipeCD and two Kubernetes clusters on your laptop, write a rollout pipeline for one app, check what it will do, then roll it out and roll it back.

**You need:** Docker running, `kind`, `kubectl`, `git`, a GitHub account, and about 8 GB of RAM. On Windows, use WSL2.

**No Docker, or your laptop is struggling?** Skip to [Without Docker](#without-docker). You still do every exercise.

## Setup (about 15 minutes)

**1. Fork this repo** on GitHub, then clone your fork:

```sh
git clone https://github.com/<you>/pipecd-multicluster-workshop.git
cd pipecd-multicluster-workshop
```

**2. Start everything:**

```sh
./scripts/setup.sh
```

**3. Log in** at http://localhost:8080?project=quickstart. User and password: `hello-pipecd`.

**4. Connect piped.** In the console, go to **Settings → Piped → + ADD**, call it `my-piped` and save. Copy the **Piped Id** and the **Base64 Encoded Piped Key**, then in a new terminal:

```sh
./scripts/piped.sh <PIPED_ID> <BASE64_PIPED_KEY>
```

Leave it running.

**5. Add the app.** Go to **Applications → + ADD → PIPED V1 ADD FROM SUGGESTIONS**. Pick `my-piped`, tick **cluster1 and cluster2**, pick `hello-ibadan`, and save. It deploys to both clusters straight away. Check:

```sh
./scripts/status.sh
```

**6. Make an API key** (needed for previews): **Settings → API Key → + ADD**, role `READ_WRITE`. Then:

```sh
echo '<your key>' > ~/.pipecd-workshop/api-key
```

## How each exercise works

```sh
git switch -c ex1                # 1. a new branch
# 2. edit files in app/hello-ibadan/
git commit -am "ex1"
./scripts/preview.sh             # 3. what would PipeCD do?
git switch main && git merge ex1 && git push   # 4. deploy it for real
./scripts/status.sh              # 5. see what changed in each cluster
```

## Exercise 1: Change the version

In `app/hello-ibadan/deployment.yaml`, change the image from `v0.47.0` to `v0.47.1`. Preview, then deploy.

You'll see `QUICK_SYNC`: with no pipeline, PipeCD updates both clusters at once. Is that safe if the new version is broken?

## Exercise 2: Add a canary pipeline

Change the image to `v0.47.2`. In `app/hello-ibadan/app.pipecd.yaml`, add this under `spec:`, and fill in the stages:

```yaml
  pipeline:
    stages:
      - name: K8S_MULTI_CANARY_ROLLOUT   # start 1 pod of the new version
        with:
          replicas: 1
      - name: WAIT                       # pause for 30 seconds
        with:
          duration: 30s
      - name: ???                        # make the new version the main one
      - name: ???                        # remove the canary pod
```

Hint: the last two are `K8S_MULTI_PRIMARY_ROLLOUT` and `K8S_MULTI_CANARY_CLEAN`. Which order?

You'll see `PIPELINE_SYNC`. Deploy it, and run `status.sh` during the wait: there's a `canary` pod in **both** clusters.

## Exercise 3: One cluster first

Change the image back to `v0.47.1`. Change your pipeline so the canary runs on **cluster1 only**, then the new version goes to both. Add this under the canary stage's `with:`:

```yaml
          multiTargets:
            - cluster1
```

Run `status.sh` during the wait: cluster1 has a canary, cluster2 doesn't.

Bonus: send all of cluster1's traffic to the canary with the `K8S_MULTI_TRAFFIC_ROUTING` stage (`all: canary`). See `solutions/ex3-one-cluster-first.yaml`.

## Exercise 4: Roll back

Change the image to `v9.9.9`, a version that doesn't exist, and deploy. While it's on the `WAIT` stage, open the deployment in the console and click **Cancel**, choosing roll back. PipeCD puts **both** clusters back to the last good version.

## Without Docker

1. Fork this repo on GitHub.
2. Open your fork, press `.` to open the web editor, and make the exercise changes there.
3. Commit to a new branch and open a pull request against `mohammedfirdouss/pipecd-multicluster-workshop`. Put your name in the title.
4. The plan preview from the facilitator's PipeCD appears as a comment on your PR within a few minutes.

## When you're done

```sh
./scripts/cleanup.sh
```

Answers are in `solutions/`. To learn more: https://pipecd.dev, or say hi in `#pipecd` on the CNCF Slack.
