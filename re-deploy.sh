#!/usr/bin/env bash
set -euo pipefail

# Load configuration
source .config

CLEAN_INSTALL=true

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

# Load configuration
source .config

# List of available WordPress images
WORDPRESS_IMAGES=(
    "wordpress:latest"
    "wordpress:6-php8.4"
    "wordpress:6.8-php8.3"
    "wordpress:6.8-php8.2"
    "wordpress:6.8-php8.1"
    "wordpress:6.7-php8.0"
    "wordpress:6-php7.4"
    "wordpress:php8.2"
    "wordpress:php8.1"
    "wordpress:php8.0"
    "wordpress:php7.4"
    "wordpress:php7.3"
    "wordpress:php7.2"
    "wordpress:php7.1"
)

# Interactive image selection
echo "Available WordPress images:"
for i in "${!WORDPRESS_IMAGES[@]}"; do
    echo "  $((i+1)). ${WORDPRESS_IMAGES[$i]}"
done

read -p "Select WordPress image number [1-${#WORDPRESS_IMAGES[@]}]: " IMAGE_NUM
if [[ $IMAGE_NUM -ge 1 && $IMAGE_NUM -le ${#WORDPRESS_IMAGES[@]} ]]; then
    WORDPRESS_IMAGE="${WORDPRESS_IMAGES[$((IMAGE_NUM-1))]}"
else
    echo "⚠️ Invalid selection, using default: $WORDPRESS_IMAGE"
fi

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

# Ensure required variables are set
export DOMAIN=${DOMAIN:-$LOCAL_DOMAIN}
export WORDPRESS_IMAGE=${WORDPRESS_IMAGE:-"wordpress:6.8.0-php8.2"}

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

