#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/cloudops"
CONTAINER_NAME="cloudops-api"
CANDIDATE_NAME="cloudops-api-candidate"
IMAGE="${CLOUDOPS_IMAGE:-}"
HEALTH_URL="http://127.0.0.1:18000/health"

if [[ -z "$IMAGE" ]]; then
    echo "ERROR: Set CLOUDOPS_IMAGE to the approved image tag."
    exit 1
fi

if [[ ! -f "$APP_DIR/.env" ]]; then
    echo "ERROR: $APP_DIR/.env is missing."
    exit 1
fi

docker info >/dev/null

echo "Pulling image: $IMAGE"
docker pull "$IMAGE"

docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true

echo "Starting candidate container..."
docker run -d \
    --name "$CANDIDATE_NAME" \
    --restart no \
    --env-file "$APP_DIR/.env" \
    --publish 127.0.0.1:18000:8000 \
    "$IMAGE"

healthy=false
for attempt in {1..12}; do
    if curl --fail --silent "$HEALTH_URL" >/dev/null; then
        healthy=true
        break
    fi
    sleep 5
done

if [[ "$healthy" != true ]]; then
    echo "ERROR: Candidate failed its health check."
    docker logs --tail 50 "$CANDIDATE_NAME" || true
    docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true
    exit 1
fi

echo "Candidate is healthy."
echo "Automatic traffic switching is not configured yet."
echo "Stopping before replacing the existing container."
docker rm -f "$CANDIDATE_NAME"
