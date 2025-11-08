# Command format guide:
  # ./start-dev.sh <container-name> <port> <.net version>

# /bin/bash
# Start Podman Compose for .NET dev environment with version and port

set -euo pipefail
cd "$(dirname "$0")"

# Usage: ./start-dev.sh <container_name> <port> <dotnet_version>
CONTAINER_NAME="${1:-$(basename "$(pwd)")_dev}"
PORT="${2:-5000}"
DOTNET_VERSION="${3:-9.0}"

# Fix VS Code shared cache permissions (prevents 403 or EACCES)
sudo rm -rf ~/.cache/vscode-server-shared
mkdir -p ~/.cache/vscode-server-shared/bin
sudo chown -R 1000:1000 ~/.cache/vscode-server-shared

echo "🚀 Building & starting container '$CONTAINER_NAME' (.NET $DOTNET_VERSION, port $PORT)..."

# Run compose with passed vars
CONTAINER_NAME="$CONTAINER_NAME" PORT="$PORT" DOTNET_VERSION="$DOTNET_VERSION" \
podman-compose up -d --build

echo "✅ Container '$CONTAINER_NAME' started on port $PORT"
