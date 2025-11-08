#!/bin/bash
# -----------------------------
# Start Podman Compose for .NET dev environment
# Usage:
#   ./start-dev.sh <container-name> <port> <dotnet version>
# Example:
#   ./start-dev.sh school 5000 9.0
# -----------------------------

set -euo pipefail
cd "$(dirname "$0")"

CUSTOM_NAME="${1:-}"
PORT="${2:-5000}"
DOTNET_VERSION="${3:-9.0}"

# Build container name dynamically (same pattern as Angular)
if [ -z "$CUSTOM_NAME" ]; then
  CONTAINER_NAME="backend_dotnet-v${DOTNET_VERSION}_p${PORT}_dev"
else
  CONTAINER_NAME="${CUSTOM_NAME}_dotnet-v${DOTNET_VERSION}_p${PORT}_dev"
fi

# Fix VS Code shared cache permissions
sudo rm -rf ~/.cache/vscode-server-shared
mkdir -p ~/.cache/vscode-server-shared/bin
sudo chown -R 1000:1000 ~/.cache/vscode-server-shared

echo "🚀 Building & starting .NET container '$CONTAINER_NAME' (.NET $DOTNET_VERSION, port $PORT)..."

if CONTAINER_NAME="$CONTAINER_NAME" PORT="$PORT" DOTNET_VERSION="$DOTNET_VERSION" \
   podman-compose -f podman-compose.backend.yml up -d --build; then
  echo "✅ Container '$CONTAINER_NAME' started successfully (.NET $DOTNET_VERSION) on port $PORT"
else
  echo "❌ Failed to start container '$CONTAINER_NAME' (.NET $DOTNET_VERSION)"
  exit 1
fi
