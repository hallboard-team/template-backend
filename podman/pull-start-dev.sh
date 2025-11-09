#!/bin/bash
# -----------------------------
# Start Podman Compose for .NET dev environment (shared stack)
# Usage:
#   ./pull-start-dev.sh <port> [dotnet_version]
# Example:
#   ./pull-start-dev.sh 5000 9.0
# -----------------------------

set -euo pipefail
cd "$(dirname "$0")"

PORT="${1:-5000}"
DOTNET_VERSION="${2:-9.0}"
IMAGE="ghcr.io/hallboard-team/dotnet-v${DOTNET_VERSION}:latest"
CONTAINER_NAME="backend_dotnet-v${DOTNET_VERSION}_p${PORT}_dev"

# Fix VS Code shared cache permissions
sudo rm -rf ~/.cache/vscode-server-shared
mkdir -p ~/.cache/vscode-server-shared/bin
sudo chown -R 1000:1000 ~/.cache/vscode-server-shared

# Check if the port is already in use
if ss -tuln | grep -q ":${PORT} "; then
  echo "⚠️  Port ${PORT} is already in use. Please choose another port."
  exit 1
fi

echo "🔍 Checking for image: $IMAGE"

# Pull image manually and verify success
if ! podman pull "$IMAGE"; then
  echo "❌ Failed to pull image '$IMAGE'. Ensure it exists on GHCR."
  exit 1
fi

echo "🚀 Starting .NET container '$CONTAINER_NAME' (.NET $DOTNET_VERSION, port $PORT)..."

# Start container without building
if CONTAINER_NAME="$CONTAINER_NAME" PORT="$PORT" DOTNET_VERSION="$DOTNET_VERSION" \
   podman-compose -f podman-compose.backend.yml up -d; then

  # Verify the container is running
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
