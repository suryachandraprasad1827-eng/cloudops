#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/cloudops"
CONTAINER_NAME="cloudops-api"
IMAGE="${CLOUDOPS_IMAGE:-}"

if [[ -z "$IMAGE" ]]; then
    echo "ERROR: Set CLOUDOPS_IMAGE to the approved image tag."
    exit 1
fi

if [[ ! -f "$APP_DIR/.env" ]]; then
    echo "ERROR: $APP_DIR/.env is missing."
    echo "Create the environment file securely before deployment."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker is not running or this user cannot access it."
    exit 1
fi

echo "Pulling application image..."
docker pull "$IMAGE"

echo "Replacing application container..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

docker run -d \
    --name "$CONTAINER_NAME" \
    --restart unless-stopped \
    --env-file "$APP_DIR/.env" \
    --publish 127.0.0.1:8000:8000 \
    "$IMAGE"

echo "Waiting for application health..."
for attempt in {1..12}; do
    if curl --fail --silent http://127.0.0.1:8000/health >/dev/null; then
        echo "CloudOps is healthy."
        exit 0
    fi
    sleep 5
done

echo "ERROR: Health check failed. Recent container logs:"
docker logs --tail 50 "$CONTAINER_NAME" || true
exit 1
