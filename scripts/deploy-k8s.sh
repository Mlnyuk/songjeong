#!/usr/bin/env bash
set -euo pipefail
if [[ $# -ne 1 || -z "$1" ]]; then
  echo "Usage: bash scripts/deploy-k8s.sh <destination-kube-context>" >&2
  exit 2
fi
target_context=$1
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
kubectl --context "$target_context" get namespace >/dev/null
kubectl --context "$target_context" apply -k "$project_dir"
kubectl --context "$target_context" -n songjeong rollout status deployment/songjeong-web --timeout=180s
kubectl --context "$target_context" -n songjeong get service songjeong-web -o wide
