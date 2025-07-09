#!/bin/bash

AUTH_FILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --auth-file)
            AUTH_FILE="$2"
            shift 2
            ;;
        *)
            echo "❌ Unknown argument: $1"
            exit 1
            ;;
    esac
done

if [[ -n "$AUTH_FILE" && -f "$AUTH_FILE" ]]; then
    # Read container names from auth file (first CSV column)
    mapfile -t STUDENTS < <(grep -v '^\s*$' "$AUTH_FILE")
    CONTAINERS=()
    for entry in "${STUDENTS[@]}"; do
        STUDENT_NAME=$(echo "$entry" | cut -d',' -f1)
        CONTAINERS+=("code-$STUDENT_NAME")
    done
else
    # No auth file, fallback to all containers matching code-student*
    CONTAINERS=( $(docker ps -aq --filter "name=code-student") )
fi

if [ ${#CONTAINERS[@]} -eq 0 ]; then
    echo "⚠️ No matching containers found to stop."
    exit 0
fi

echo "🛑 Stopping ${#CONTAINERS[@]} code-server student containers..."
docker stop "${CONTAINERS[@]}"
echo "✅ Student containers stopped."

read -p "❓ Do you want to remove the containers too? [y/N]: " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "🧹 Removing code-server student containers..."
    docker rm "${CONTAINERS[@]}"
    echo "✅ Student containers removed."
else
    echo "❎ Skipping container removal."
fi
