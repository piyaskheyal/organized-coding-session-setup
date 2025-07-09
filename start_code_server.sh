#!/bin/bash

BASE_DIR="/home/kheyal/dev/organized-coding-session-setup/students"
START_PORT=8081
STUDENT_COUNT=2
IMAGE="rsr-code-server:cpp"
MAX_PORT=9000  # Safety cap for port scanning

mkdir -p "$BASE_DIR"

echo -e "🛠 Setting up $STUDENT_COUNT student containers...\n"

i=1
port=$START_PORT
success_count=0

PASSWORD_FILE=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --password-file)
            PASSWORD_FILE="$2"
            shift 2
            ;;
        *)
            echo "❌ Unknown argument: $1"
            exit 1
            ;;
    esac
done

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

    if [ -n "$PASSWORD_FILE" ] && [ -f "$PASSWORD_FILE" ]; then
        PASSWORD=$(sed -n "${i}p" "$PASSWORD_FILE")
        if [ -z "$PASSWORD" ]; then
            echo "⚠️ No password found for $STUDENT_NAME in $PASSWORD_FILE. Generating random one."
            PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c10)
        fi
    else
        # Fallback to random password
        PASSWORD=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c10)
    fi

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
        echo -e "$STUDENT_NAME | Port: $port | Password: $PASSWORD\n"
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
