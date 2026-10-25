# Workshop guide

Today you'll run PipeCD and **two Kubernetes clusters on your own laptop**. You'll update one app on both clusters, check what will change first, watch it go live step by step, then undo a bad update.

## Start the setup now ⏱️

It downloads about **1.2 GB**, so start it straight away. Use your hotspot or the Wi-Fi. It runs while you listen to the intro.

**You need:**
- Docker running (Docker Desktop, OrbStack or Rancher Desktop). On Windows, use WSL2.
- `kind`, `kubectl` and `git`
- About 4 GB of free memory
- A GitHub account

**No Docker, or your laptop is struggling?** Use [the no-install way](#no-install-way) instead. You still do every exercise.

1. **Fork** https://github.com/mohammedfirdouss/pipecd-multicluster-workshop on GitHub, then:
   ```sh
   git clone https://github.com/<you>/pipecd-multicluster-workshop.git
   cd pipecd-multicluster-workshop
   ./scripts/setup.sh
   ```
2. When it says **Done**, open http://localhost:8080?project=quickstart. User and password are both `hello-pipecd`.
3. **Connect piped** (the agent that does the deploying):
   - Go to **Settings → Piped → + ADD**. Type any name and description, then **Save**.
   - Copy the **Piped Id** and the **Base64 Encoded Piped Key**.
   - In a **new terminal**, run this and leave it running:
     ```sh
     ./scripts/piped.sh <PIPED_ID> <BASE64_PIPED_KEY>
     ```
4. **Add the app:**
   - Go to **Applications → + ADD → PIPED V1 ADD FROM SUGGESTIONS**.
   - Pick your piped. Under **Deploy targets**, pick **cluster1** and **cluster2**. Pick `hello-ibadan`. Then **Save**.
   - After a minute or two, check that both clusters run it:
     ```sh
     ./scripts/status.sh
     ```
5. **Make an API key** (for previews):
   - Go to **Settings → API Key → + ADD**. Pick role **Read/Write**, then **Generate**, and copy the key.
   - Save it:
     ```sh
     echo '<your key>' > ~/.pipecd-workshop/api-key
     ```

## How each exercise works

```sh
git switch -c ex1                              # 1. new branch
# 2. edit files in app/hello-ibadan/
git commit -am "ex1"
./scripts/preview.sh                           # 3. what would change?
git switch main && git merge ex1 && git push   # 4. deploy it
./scripts/status.sh                            # 5. look at both clusters
```

You can also watch each deployment in the browser, under **Deployments**.

## Exercise 1: Change the version

In `app/hello-ibadan/deployment.yaml`, change `v0.47.0` to `v0.47.1`. Preview it, then deploy it.

**You should see:** `QUICK_SYNC`. PipeCD updates **both clusters at once**. What if the new version is broken?

(Both clusters get the same files, so the preview shows the change once, under `cluster1`.)

## Exercise 2: Update slowly (canary)

A **canary** is a small test: run one copy of the new version first, wait, then update everything.

Change the version to `v0.47.2`. In `app/hello-ibadan/app.pipecd.yaml`, add this under `spec:` and fill in the two `???`:

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

The missing names are `K8S_MULTI_PRIMARY_ROLLOUT` and `K8S_MULTI_CANARY_CLEAN`. Which goes first?

**You should see:** `PIPELINE_SYNC`. While it waits, `status.sh` shows a `canary` copy on **both** clusters.

## Exercise 3: One cluster first

Big teams don't update every region at once. Change the version back to `v0.47.1`, and this time try it on **cluster1 only** first.

Add this inside the canary step, under `with:`:

```yaml
          multiTargets:
            - cluster1
```

Add a step right after it, to send cluster1's users to the new version:

```yaml
      - name: K8S_MULTI_TRAFFIC_ROUTING
        with:
          all: canary
          multiTargets:
            - cluster1
```

Before the clean-up step, send them back with `all: primary`. The full answer is in `solutions/ex3-one-cluster-first.yaml`.

While it waits, `status.sh` shows the canary only on cluster1.

Why "all"? Without an extra tool like Istio, users can only go to one version at a time.

## Exercise 4: Undo a bad update

Change the `WAIT` to `2m`, and the version to `v9.9.9`, a version that doesn't exist. Deploy it. While it's waiting, open it under **Deployments** and click the arrow next to **Cancel**, then **Cancel with Rollback**. Both clusters go back to the last good version.

Note: PipeCD only checks that the new version works if you add a check step (`ANALYSIS`). Without it, a broken update can still say "success".

## No-install way

1. Fork this repo, open your fork, and press `.` to edit in the browser.
2. Make the exercise change, and save it to a new branch.
3. Open a pull request to `mohammedfirdouss/pipecd-multicluster-workshop`, branch `main`. Put your name in the title.
4. The facilitator's PipeCD posts the preview as a comment on your PR within a few minutes.

## When you're done

```sh
./scripts/cleanup.sh
```

Learn more at https://pipecd.dev, or say hi in `#pipecd` on the CNCF Slack.
