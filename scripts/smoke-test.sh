#!/usr/bin/env bash
# Docker, curl and cmp are required. Uses a temporary loopback-only container.
set -euo pipefail
project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_image=${TEST_IMAGE:-songjeong-web:smoke}
container_id=
response_file=$(mktemp)
cleanup() {
  if [[ -n "$container_id" ]]; then docker rm -f "$container_id" >/dev/null; fi
  rm -f "$response_file"
}
trap cleanup EXIT
docker build -t "$test_image" "$project_dir"
container_id=$(docker run -d --read-only --tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
  --cap-drop ALL --security-opt no-new-privileges:true -p 127.0.0.1::8080 "$test_image")
test_port=$(docker port "$container_id" 8080/tcp | sed -n 's/^127\.0\.0\.1://p')
curl --fail --silent --show-error --retry 20 --retry-connrefused --retry-delay 1 \
  --max-time 5 --retry-max-time 30 "http://127.0.0.1:$test_port/" -o "$response_file"
cmp "$project_dir/site/index.html" "$response_file"
docker exec "$container_id" nginx -t
echo 'PASS: HTTP 200, response matches site/index.html, Nginx configuration valid.'
