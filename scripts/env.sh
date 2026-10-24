# Settings shared by the scripts. You don't run this file directly.

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOME_DIR="$HOME/.pipecd-workshop"          # tools, kubeconfigs and keys live here
mkdir -p "$HOME_DIR/bin" "$HOME_DIR/kube"
export PATH="$HOME_DIR/bin:$PATH"

# Your fork: piped deploys whatever is on its main branch.
REPO_URL="$(git -C "$REPO_DIR" remote get-url origin | sed -E 's#^git@github.com:#https://github.com/#')"
case "$REPO_URL" in *.git) ;; *) REPO_URL="$REPO_URL.git" ;; esac
