#!/usr/bin/env bash

set -euo pipefail

usage() {
    echo "Usage:"
    echo "  $0 <class|interface|enum|controller|service|dto> <Name> [target-directory]"
    echo
    echo "Example:"
    echo "  $0 class Product src/Catalog/Models"
    exit 1
}

[[ $# -lt 2 ]] && usage

TYPE="$1"
NAME="$2"
TARGET_DIR="${3:-.}"

# Remove a possible .cs extension from the supplied name
NAME="${NAME%.cs}"

# Convert the target directory to an absolute path.
TARGET_DIR="$(realpath -m "$TARGET_DIR")"

if [[ ! -d "$TARGET_DIR" ]]; then
    mkdir -p "$TARGET_DIR"
fi

# Find the nearest .csproj by walking upward from the target directory.
find_nearest_csproj() {
    local directory="$1"

    while [[ "$directory" != "/" ]]; do
        local project

        project="$(find "$directory" -maxdepth 1 -type f -name '*.csproj' -print -quit)"

        if [[ -n "$project" ]]; then
            echo "$project"
            return 0
        fi

        directory="$(dirname "$directory")"
    done

    return 1
}

CSPROJ="$(find_nearest_csproj "$TARGET_DIR" || true)"

if [[ -z "$CSPROJ" ]]; then
    echo "Error: Could not find a .csproj file at or above:"
    echo "  $TARGET_DIR"
    exit 1
fi

PROJECT_DIR="$(dirname "$CSPROJ")"
PROJECT_NAME="$(basename "$CSPROJ" .csproj)"

# Prefer RootNamespace from the project file.
ROOT_NAMESPACE="$(
    sed -n 's:.*<RootNamespace>[[:space:]]*\([^<]*\)[[:space:]]*</RootNamespace>.*:\1:p' "$CSPROJ" |
    head -n 1
)"

# Fall back to the project filename.
ROOT_NAMESPACE="${ROOT_NAMESPACE:-$PROJECT_NAME}"

# Get the target path relative to the project directory.
RELATIVE_DIR="$(realpath --relative-to="$PROJECT_DIR" "$TARGET_DIR")"

# Build namespace suffix from the directory structure.
if [[ "$RELATIVE_DIR" == "." ]]; then
    NAMESPACE="$ROOT_NAMESPACE"
elif [[ "$RELATIVE_DIR" == ..* ]]; then
    echo "Warning: target directory is outside the project directory."
    NAMESPACE="$ROOT_NAMESPACE"
else
    NAMESPACE="$ROOT_NAMESPACE.$(
        echo "$RELATIVE_DIR" |
        tr '/' '.' |
        sed 's/[^a-zA-Z0-9_.]/_/g'
    )"
fi

# Clean namespace segments and remove duplicate dots.
NAMESPACE="$(
    echo "$NAMESPACE" |
    sed 's/[^a-zA-Z0-9_.]/_/g; s/\.\+/\./g; s/^\.//; s/\.$//'
)"

case "$TYPE" in
    class)
        DECLARATION="public class $NAME"
        ;;

    interface)
        [[ "$NAME" != I* ]] && NAME="I$NAME"
        DECLARATION="public interface $NAME"
        ;;

    enum)
        DECLARATION="public enum $NAME"
        ;;

    controller)
        [[ "$NAME" != *Controller ]] && NAME="${NAME}Controller"
        DECLARATION="public class $NAME : ControllerBase"
        ;;

    service)
        [[ "$NAME" != *Service ]] && NAME="${NAME}Service"
        DECLARATION="public class $NAME"
        ;;

    dto)
        [[ "$NAME" != *Dto ]] && NAME="${NAME}Dto"
        DECLARATION="public sealed record $NAME"
        ;;

    *)
        echo "Error: Unsupported type '$TYPE'"
        usage
        ;;
esac

FILE_PATH="$TARGET_DIR/$NAME.cs"

if [[ -e "$FILE_PATH" ]]; then
    echo "Error: File already exists:"
    echo "  $FILE_PATH"
    exit 1
fi

{
    echo "namespace $NAMESPACE;"
    echo

    case "$TYPE" in
        controller)
            echo "using Microsoft.AspNetCore.Mvc;"
            echo
            echo "$DECLARATION"
            echo "{"
            echo "}"
            ;;

        dto)
            echo "$DECLARATION"
            echo "("
            echo
            echo ");"
            ;;

        *)
            echo "$DECLARATION"
            echo "{"
            echo "}"
            ;;
    esac
} > "$FILE_PATH"

echo "Created:"
echo "  $FILE_PATH"
echo
echo "Namespace:"
echo "  $NAMESPACE"
echo
echo "Project:"
echo "  $CSPROJ"