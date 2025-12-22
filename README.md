# Template Backend Dev Environment

Containerized development template for .NET projects using VS Code Dev Containers and Docker Compose. It ships with a prebuilt image from `ghcr.io/hallboard-team/dotnet` so you can focus on writing code instead of wiring up tooling.

## Prerequisites
- Docker Desktop (or Docker Engine + Docker Compose v2)
- VS Code with the **Dev Containers** extension
- Git (to clone the template and keep your history)

## Repository Layout
- `src/` – place your solution or create a new one here. The entire repo is mounted into the container at `/workspaces/app`, so project-relative paths continue to work.
- `.devcontainer/` – Dev Container definition along with the compose file that runs the backend service.
- `.vscode/` – opinionated editor settings/extensions shared with the team.

## Getting Started
1. Clone this template and rename the folder/repo as needed.
2. Create or copy your .NET project inside `src/`. For example, from the host you can run:
   ```bash
   cd src
   dotnet new webapi -n MyService
   ```
3. Open the repo in VS Code and run **Dev Containers: Reopen in Container**. VS Code will build/pull the image (`ghcr.io/hallboard-team/dotnet:10.0-sdk` by default) and start the `api` service defined in `.devcontainer/docker/docker-compose.backend.yml`.
4. Once the container is up, use the `api` terminal to run the usual .NET commands (`dotnet restore`, `dotnet test`, etc.). The devcontainer keeps the container alive with `sleep infinity`, so you control processes from VS Code tasks or terminals.

## Configuration
You can tweak a few settings through environment variables consumed by the compose file:

| Variable | Default | Purpose |
| --- | --- | --- |
| `DOTNET_VERSION` | `10.0` | Chooses the SDK tag in `ghcr.io/hallboard-team/dotnet:<version>-sdk`. |
| `COMPOSE_PROJECT_NAME` | `template` | Prefix for the dev container (`${COMPOSE_PROJECT_NAME}_api-dev`). |
| `PORT` | `5000` | Host port forwarded to the container's port 5000. |

Set them in a `.env` file next to the compose file or in your VS Code workspace settings if you want different defaults.

## Tips
- The shared VS Code server cache is mounted at `${HOME}/.cache/vscode-server-shared` so language services stay fast across projects.
- Keep secrets out of the repo; use `dotnet user-secrets` (already available via the installed extensions) for local development.
- If you need additional tooling, extend the compose file or build a custom image derived from `ghcr.io/hallboard-team/dotnet:<version>-sdk`.
