#!/usr/bin/env bash
#Scritps Runs inside the Docker container to 
#re-deploy a WordPress stack with 
#persistent data

set -euo pipefail


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

# Interactive image selection
echo "Available WordPress images:"
for i in "${!WORDPRESS_IMAGES[@]}"; do
    echo "  $((i+1)). ${WORDPRESS_IMAGES[$i]}"
done

read -p "Select WordPress image number [1-${#WORDPRESS_IMAGES[@]}]: " IMAGE_NUM
if [[ $IMAGE_NUM -ge 1 && $IMAGE_NUM -le ${#WORDPRESS_IMAGES[@]} ]]; then
    WORDPRESS_IMAGE="${WORDPRESS_IMAGES[$((IMAGE_NUM-1))]}"
    echo "Selected WordPress image: $WORDPRESS_IMAGE"
    export WORDPRESS_IMAGE="${WORDPRESS_IMAGE}"
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


# Update DOMAIN in .env file
if grep -q '^DOMAIN=' "$STACK_ENV_FILE"; then
    sed -i "s/^DOMAIN=.*/DOMAIN=$DOMAIN/" "$STACK_ENV_FILE"
    sed -i "s/^WORDPRESS_IMAGE=.*/WORDPRESS_IMAGE=$WORDPRESS_IMAGE/" "$STACK_ENV_FILE"
    echo "Updated DOMAIN and WORDPRESS_IMAGE in $STACK_ENV_FILE"
else
    echo "DOMAIN=$DOMAIN" >> "$STACK_ENV_FILE"
fi


echo
echo "🔁 Re-deploying Docker stack: $STACK_NAME"
echo "🗂️ Using existing environment file: $STACK_ENV_FILE"
echo "📂 Reusing persistent volumes: ./db and ./data"
echo


echo
echo "✅ Generated .env file: $STACK_ENV_FILE"
echo "📦 Deploying stack: $STACK_NAME"
echo "------------------------------------------------------"
echo "  WordPress     → http://${DOMAIN}:${WP_HTTP_PORT}"
echo "  WordPress SSL → https://${DOMAIN}:${WP_HTTPS_PORT}"
echo "  phpMyAdmin    → http://${DOMAIN}:${PHPMYADMIN_PORT}"
echo "------------------------------------------------------"
echo "  MYSQL_USER    → ${MYSQL_USER}"
echo "  MYSQL_PASS    → ${MYSQL_PASSWORD}"
echo "  WP DB User    → ${WORDPRESS_DB_USER}"
echo "  WP DB Pass    → ${WORDPRESS_DB_PASSWORD}"
echo "  Root MySQL    → ${MYSQL_ROOT_PASSWORD}"
echo "  PMA Root Pass → ${PMA_ROOT_PASSWORD}"
echo "------------------------------------------------------"


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

# Output Linux version from inside all running services
echo -e "\n🖥️ Linux version inside running services:"
for service in $(docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" ps --services); do
    echo -n "$service: "
    if docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" exec -T $service sh -c 'if [ -f /etc/os-release ]; then grep -E "^(PRETTY_NAME|VERSION_ID)=" /etc/os-release | cut -d= -f2 | tr -d \"\" | paste -sd ", " -; else uname -a; fi' 2>/dev/null; then
        :
    else
        echo "(not running or no shell access)"
    fi
done
echo -e "\n🖥"

# Run post-install script
# Wait for WordPress to be ready
#echo "⏳ Waiting for WordPress to be ready..."
#sleep 10
echo "🏗️ Running post-install script..."
docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" exec -w /var/www/html wordpress bash wp-content/post-install.sh

echo -e "\n📜 Showing logs (press Ctrl+C to exit)..."
echo "------------------------------------------------------"
docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" logs -f || true

echo -e "\n✅ Re-deployment complete!"
echo "You can view logs anytime with:"
echo "  docker compose -p $STACK_NAME logs -f"
echo "Or re-deploy with automatic logs using:"
echo "  ./re-deploy.sh --logs"

