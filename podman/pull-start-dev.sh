#!/bin/bash
# -----------------------------
# Pull & Start Podman Compose for .NET dev environment (shared stack)
# Usage:
#   ./pull-start-dev.sh <port> [dotnet_version]
# Example:
#   ./pull-start-dev.sh 5000 9.0
# -----------------------------

set -euo pipefail
cd "$(dirname "$0")"

# Ensure the repo is owned by the current user (avoid permission hell in the container)
if [ "$(stat -c %u ..)" != "$(id -u)" ]; then
  echo "⚠ Repo at '$(cd .. && pwd)' is not owned by user $(id -un) (uid $(id -u))."
  echo "   This will break devcontainers because the container runs as uid $(id -u)."
  echo
  echo "   Fix it once on the host with:"
  echo "     sudo chown -R $(id -u):$(id -g) '$(cd .. && pwd)'"
  echo
  exit 1
fi

PORT="${1:-5000}"
DOTNET_VERSION="${2:-9.0}"
IMAGE="ghcr.io/hallboard-team/dotnet-v${DOTNET_VERSION}:latest"
CONTAINER_NAME="backend_dotnet-v${DOTNET_VERSION}_p${PORT}_dev"
COMPOSE_FILE="podman-compose.backend.yml"

# Fix VS Code shared cache permissions
sudo rm -rf ~/.cache/vscode-server-shared
mkdir -p ~/.cache/vscode-server-shared/bin
chown -R 1000:1000 ~/.cache/vscode-server-shared

# Ensure the image exists locally (PULL, don't build)
if podman image exists "$IMAGE"; then
  echo "🧱 Image '$IMAGE' already exists locally — skipping pull."
else
  echo "📥 Pulling dev image '$IMAGE' from GHCR..."
  if ! podman pull "$IMAGE"; then
    echo "❌ Failed to pull image '$IMAGE'. Make sure it exists and you are logged in to GHCR."
    exit 1
  fi
fi

# Check if the port is already in use
if ss -tuln | grep -q ":${PORT} "; then
  echo "⚠️  Port ${PORT} is already in use. Please choose another port."
  exit 1
fi

echo "🚀 Starting .NET container '$CONTAINER_NAME' (.NET $DOTNET_VERSION, port $PORT)..."

# Start container WITHOUT building
if CONTAINER_NAME="$CONTAINER_NAME" PORT="$PORT" DOTNET_VERSION="$DOTNET_VERSION" \
   podman-compose -f "$COMPOSE_FILE" up -d; then

  if podman ps --filter "name=$CONTAINER_NAME" --format '{{.Names}}' | grep -q "$CONTAINER_NAME"; then
    echo "✅ Container '$CONTAINER_NAME' started successfully (.NET $DOTNET_VERSION) on port $PORT"
  else
    echo "❌ Container '$CONTAINER_NAME' did not start properly even though compose succeeded."
    exit 1
  fi
else
  echo "❌ podman-compose failed to start container '$CONTAINER_NAME'."
  exit 1
fi
