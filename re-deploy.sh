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
STACK_ENV_FILE=".env"

# Load environment variables from the stack file
if [[ -f "$STACK_ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$STACK_ENV_FILE"
else
  # Check if the environment file exists
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

# Clean install option
if [ "$CLEAN_INSTALL" = true ]; then
    echo "🧹 Performing clean install - removing all files except wp-content..."
    if [ -d "./data" ]; then
        # Remove everything except wp-content
        find ./data -mindepth 1 -maxdepth 1 ! -name 'wp-content' -exec rm -rf {} +
        echo "✅ Removed all files except wp-content directory"
    fi
fi

# Start updated stack with persistent data and show logs
docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" up -d

# Wait for WordPress to be ready
echo "⏳ Waiting for WordPress to be ready..."
sleep 10

# Run post-install script
echo "🏗️ Running post-install script..."
docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" exec -w /var/www/html wordpress bash wp-content/post-install.sh

echo -e "\n📜 Showing logs (press Ctrl+C to exit)..."
echo "------------------------------------------------------"
timeout 30 docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" logs -f || true

echo -e "\n✅ Re-deployment complete!"
echo "You can view logs anytime with:"
echo "  docker compose -p $STACK_NAME logs -f"
echo "Or re-deploy with automatic logs using:"
echo "  ./re-deploy.sh --logs"

