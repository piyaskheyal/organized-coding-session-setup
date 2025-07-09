#!/bin/bash

BASE_DIR="$HOME/dev/students"
START_PORT=8081
STUDENT_COUNT=2
IMAGE="rsr-code-server:cpp"
MAX_PORT=9000  # Safety cap for port scanning

mkdir -p "$BASE_DIR"

echo "🛠 Setting up $STUDENT_COUNT student containers..."

i=1
port=$START_PORT
success_count=0

while [ $success_count -lt $STUDENT_COUNT ] && [ $port -lt $MAX_PORT ]; do
    # Check if port is available
    if ss -tuln | grep -q ":$port "; then
        echo "⚠️  Port $port is in use. Skipping..."
        port=$((port + 1))
        continue
    fi

    STUDENT_NAME=$(printf "student%02d" "$i")
    CONTAINER_NAME="code-$STUDENT_NAME"
    STUDENT_DIR="$BASE_DIR/$STUDENT_NAME"

    # Generate a random 10-character password
    PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c10)

    echo "🚀 Setting up $STUDENT_NAME on port $port"

    mkdir -p "$STUDENT_DIR"

    docker run -d \
        --name "$CONTAINER_NAME" \
        -p "$port":8080 \
        -v "$STUDENT_DIR":/home/coder/project \
        -e PASSWORD="$PASSWORD" \
        --restart unless-stopped \
        "$IMAGE"

    if [ $? -eq 0 ]; then
        echo "$STUDENT_NAME | Port: $port | Password: $PASSWORD"
        i=$((i + 1))
        success_count=$((success_count + 1))
    else
        echo "❌ Failed to start container for $STUDENT_NAME on port $port"
    fi

    port=$((port + 1))
done

if [ $success_count -lt $STUDENT_COUNT ]; then
    echo "⚠️ Only $success_count out of $STUDENT_COUNT containers started. Some ports may be blocked or failed."
else
    echo "✅ All $STUDENT_COUNT student containers have been set up."
fi

echo "📝 You can access them at http://<your-local-IP>:PORT"
