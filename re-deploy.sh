#!/usr/bin/env bash
set -euo pipefail

# Prompt for stack name
read -p "Enter the name of your Docker stack: " STACK_NAME
STACK_ENV_FILE=".env-${STACK_NAME}"

# Check if the environment file exists
if [[ ! -f "$STACK_ENV_FILE" ]]; then
  echo "❌ Error: Environment file '$STACK_ENV_FILE' not found."
  echo "   You must reuse the original env file from the first deployment."
  exit 1
fi

echo
echo "🔁 Re-deploying Docker stack: $STACK_NAME"
echo "🗂️ Using existing environment file: $STACK_ENV_FILE"
echo "📂 Reusing persistent volumes: ./db and ./data"
echo

# Optional: Pull updated images if you've changed versions
docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" pull

# Gracefully stop old containers (without removing volumes!)
docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" down

# Start updated stack with persistent data
docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" up -d

