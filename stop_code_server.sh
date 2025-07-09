#!/bin/bash

echo "🛑 Stopping all code-server student containers..."
docker ps -aq --filter "name=code-student" | xargs -r docker stop
echo "✅ All student containers stopped."

read -p "❓ Do you want to remove the containers too? [y/N]: " confirm

if [[ "$confirm" =~ ^[Yy]$ ]]; then
    echo "🧹 Removing all code-student containers..."
    docker ps -aq --filter "name=code-student" | xargs -r docker rm
    echo "✅ All student containers removed."
else
    echo "❎ Skipping container removal."
fi
