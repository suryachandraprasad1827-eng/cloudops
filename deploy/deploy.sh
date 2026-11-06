
#!/usr/bin/env bash
set -Eeuo pipefail

APP_DIR="/opt/cloudops"
CONTAINER_NAME="cloudops-api"
CANDIDATE_NAME="cloudops-api-candidate"
DOCKER_NETWORK="cloudops_default"
IMAGE="${CLOUDOPS_IMAGE:-}"
HEALTH_URL="http://127.0.0.1:18000/health"

# Validate configuration
if [[ -z "$IMAGE" ]]; then
    echo "ERROR: Set CLOUDOPS_IMAGE to the approved image tag."
    exit 1
fi

if [[ ! -f "$APP_DIR/.env" ]]; then
    echo "ERROR: $APP_DIR/.env is missing."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo "ERROR: Docker is not available."
    exit 1
fi

if ! docker network inspect "$DOCKER_NETWORK" >/dev/null 2>&1; then
    echo "ERROR: Docker network $DOCKER_NETWORK does not exist."
    exit 1
fi

# Pull approved image
echo "Pulling image: $IMAGE"
docker pull "$IMAGE"

# Remove previous candidate, if present
docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true

# Start hardened candidate container
echo "Starting secured candidate container..."

docker run -d \
    --name "$CANDIDATE_NAME" \
    --restart no \
    --network "$DOCKER_NETWORK" \
    --env-file "$APP_DIR/.env" \
    -e DATABASE_HOST=cloudops-postgres \
    --publish 127.0.0.1:18000:8000 \
    --user 100:101 \
    --read-only \
    --tmpfs /tmp:rw,noexec,nosuid,size=64m \
    --memory=512m \
    --memory-swap=512m \
    --pids-limit=256 \
    --security-opt=no-new-privileges:true \
    --cap-drop=ALL \
    "$IMAGE"

# Wait for application health
healthy=false

for attempt in {1..12}; do
    if curl --fail --silent "$HEALTH_URL" >/dev/null; then
        healthy=true
        break
    fi

    sleep 5
done

# Handle failure safely
if [[ "$healthy" != true ]]; then
    echo "ERROR: Candidate failed its health check."
    docker logs --tail 50 "$CANDIDATE_NAME" || true
    docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true
    exit 1
fi

echo "Candidate is healthy."

# Verify runtime restrictions
if ! docker inspect "$CANDIDATE_NAME" \
    --format '{{.Config.User}} {{.HostConfig.ReadonlyRootfs}} {{.HostConfig.Memory}} {{.HostConfig.MemorySwap}} {{.HostConfig.PidsLimit}} {{json .HostConfig.SecurityOpt}} {{json .HostConfig.CapDrop}}' \
    | grep -Fqx '100:101 true 536870912 536870912 256 ["no-new-privileges:true"] ["ALL"]'; then
    echo "ERROR: Candidate runtime security settings do not match."
    docker rm -f "$CANDIDATE_NAME" >/dev/null 2>&1 || true
    exit 1
fi

echo "Runtime security settings verified."

echo "Automatic traffic switching is not configured yet."
echo "Existing application has not been replaced."
echo "Removing temporary candidate."

docker rm -f "$CANDIDATE_NAME"

echo "Deployment validation completed successfully."
