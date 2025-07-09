#!/bin/bash

BASE_DIR="/home/kheyal/dev/organized-coding-session-setup/students"
START_PORT=8081
IMAGE="rsr-code-server:cpp"
MAX_PORT=9000  # Safety cap for port scanning
STUDENT_NUM=10

mkdir -p "$BASE_DIR"

AUTH_FILE=""
STUDENTS=()

# --- Parse arguments ---
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

echo -e "🛠 Starting student container setup...\n"

i=1
port=$START_PORT
success_count=0

# --- If auth file exists, load names/passwords ---
if [[ -n "$AUTH_FILE" && -f "$AUTH_FILE" ]]; then
    mapfile -t STUDENTS < <(grep -v '^\s*$' "$AUTH_FILE")  # remove empty lines
else
    # Generate STUDENT_NUM students with random passwords
    for ((j=1; j<=STUDENT_NUM; j++)); do
        name=$(printf "student%02d" "$j")
        password=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9' | head -c10)
        STUDENTS+=("$name,$password")
    done
fi


for entry in "${STUDENTS[@]}"; do
    STUDENT_NAME=$(echo "$entry" | cut -d',' -f1)
    PASSWORD=$(echo "$entry" | cut -d',' -f2)

    # Find an available port
    while [ $port -lt $MAX_PORT ]; do
        if ss -tuln | grep -q ":$port "; then
            echo "⚠️  Port $port is in use. Skipping..."
            port=$((port + 1))
        else
            break
        fi
    done

    if [ $port -ge $MAX_PORT ]; then
        echo "❌ No available ports left under $MAX_PORT"
        break
    fi

    CONTAINER_NAME="code-$STUDENT_NAME"
    STUDENT_DIR="$BASE_DIR/$STUDENT_NAME"
    mkdir -p "$STUDENT_DIR"

    echo "🚀 Setting up $STUDENT_NAME on port $port"

    docker run -d \
        --name "$CONTAINER_NAME" \
        -p "$port":8080 \
        -v "$STUDENT_DIR":/home/coder/project \
        -e PASSWORD="$PASSWORD" \
        --restart unless-stopped \
        "$IMAGE"

    if [ $? -eq 0 ]; then
        echo -e "$STUDENT_NAME | Port: $port | Password: $PASSWORD\n"
        success_count=$((success_count + 1))
    else
        echo "❌ Failed to start container for $STUDENT_NAME on port $port"
    fi

    port=$((port + 1))
done

echo "✅ $success_count student container(s) have been set up."
echo "📝 Access them at: http://<your-local-IP>:PORT"
