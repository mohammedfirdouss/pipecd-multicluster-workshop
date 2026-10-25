# Run it yourself

Run PipeCD and two Kubernetes clusters on your own laptop.

**You need:** Docker running, `kind`, `kubectl`, `git`, about 4 GB of free memory and 10 GB of disk. On Windows, use WSL2. The first run downloads a few GB, so do it on good internet.

## Setup

```sh
# 1. Fork this repo on GitHub, then:
git clone https://github.com/<you>/pipecd-multicluster-workshop.git
cd pipecd-multicluster-workshop

# 2. Start everything (10–30 minutes the first time, mostly downloads)
./scripts/setup.sh
```

3. Log in at http://localhost:8080?project=quickstart. User and password are both `hello-pipecd`.
4. **Settings → Piped → + ADD**. Name it `my-piped`, add any description, and save. Copy the **Piped Id** and the **Base64 Encoded Piped Key**. In a new terminal:
   ```sh
   ./scripts/piped.sh <PIPED_ID> <BASE64_PIPED_KEY>
   ```
   Leave it running.
5. **Applications → + ADD → PIPED V1 ADD FROM SUGGESTIONS**. Pick `my-piped`, choose **cluster1 and cluster2** as deploy targets, pick `hello-ibadan`, and save. It deploys to both clusters within a minute or two:
   ```sh
   ./scripts/status.sh
   ```
6. **Settings → API Key → + ADD**, role **Read/Write**. Copy the key, then:
   ```sh
   echo '<your key>' > ~/.pipecd-workshop/api-key
   ```

## Doing the exercises

Follow [the guide](ATTENDEE-GUIDE.md), but work on your own fork:

```sh
git switch -c ex1                              # a branch per exercise
# edit files in app/hello-ibadan/
git commit -am "ex1"
./scripts/preview.sh                           # plan preview
git switch main && git merge ex1 && git push   # deploy it for real
./scripts/status.sh                            # see each cluster
```

For Exercise 4, set the `WAIT` duration to `2m` so you have time to click **Cancel with Rollback** on the deployment page.

When you're done: `./scripts/cleanup.sh`
