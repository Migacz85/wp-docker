#!/usr/bin/env bash
set -euo pipefail

# Parse command line arguments
SHOW_LOGS=false
for arg in "$@"
do
    case $arg in
        --logs)
        SHOW_LOGS=true
        shift
        ;;
        *)
        echo "Unknown argument: $arg"
        exit 1
        ;;
    esac
done

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

# Show logs if --logs flag was set
if [ "$SHOW_LOGS" = true ]; then
    echo -e "\n🔄 Waiting 5 seconds for containers to start..."
    sleep 5

    echo -e "\n📜 Showing logs (press Ctrl+C to exit)..."
    echo "------------------------------------------------------"
    timeout 30 docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" logs -f || true
fi

echo -e "\n✅ Re-deployment complete!"
echo "You can view logs anytime with:"
echo "  docker compose -p $STACK_NAME logs -f"
echo "Or re-deploy with automatic logs using:"
echo "  ./re-deploy.sh --logs"

