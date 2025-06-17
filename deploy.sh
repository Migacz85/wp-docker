#!/usr/bin/env bash
set -euo pipefail

# Ask for a stack name
read -p "Enter a name for your Docker stack: " STACK_NAME
STACK_ENV_FILE=".env-${STACK_NAME}"

# 1) Generate passwords, ports and certificates
export MYSQL_DATABASE="exampledb"
# Set domain for local development
export DOMAIN="localhost"
# Production domain for reference
export PROD_DOMAIN="portainer-eu.matrix-test.com"

# Create cert directory if not exists
mkdir -p cert

# Generate self-signed cert if not exists
if [ ! -f "cert/localhost.pem" ]; then
  echo "🔐 Generating self-signed SSL certificate for ${DOMAIN}"
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout cert/localhost-key.pem \
    -out cert/localhost.pem \
    -subj "/CN=${DOMAIN}"
fi
export MYSQL_USER="exampleuser"
export WORDPRESS_DB_USER="${MYSQL_USER}"  # Make WordPress user same as MySQL user

export MYSQL_ROOT_PASSWORD="$(openssl rand -hex 16)"
export MYSQL_PASSWORD="$(openssl rand -hex 16)"
export WORDPRESS_DB_PASSWORD="${MYSQL_PASSWORD}"  # Use same password for WordPress DB user
export PMA_ROOT_PASSWORD="$(openssl rand -hex 16)"

export WP_HTTP_PORT="$(shuf -i 20000-25000 -n1)"
export WP_HTTPS_PORT="$(shuf -i 25001-30000 -n1)"
export PHPMYADMIN_PORT="$(shuf -i 30001-35000 -n1)"

# 2) Write to named .env file
cat > "$STACK_ENV_FILE" <<EOF
# Docker stack: $STACK_NAME

# Database
MYSQL_DATABASE=${MYSQL_DATABASE}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}

# WordPress
WORDPRESS_DB_HOST=db
WORDPRESS_DB_NAME=${MYSQL_DATABASE}
WORDPRESS_DB_USER=${WORDPRESS_DB_USER}
WORDPRESS_DB_PASSWORD=${WORDPRESS_DB_PASSWORD}

# phpMyAdmin
PMA_HOST=db
PMA_ROOT_PASSWORD=${PMA_ROOT_PASSWORD}

# Ports
WP_HTTP_PORT=${WP_HTTP_PORT}
WP_HTTPS_PORT=${WP_HTTPS_PORT}
PHPMYADMIN_PORT=${PHPMYADMIN_PORT}
EOF

echo
echo "✅ Generated .env file: $STACK_ENV_FILE"
echo "📦 Deploying stack: $STACK_NAME"
echo "------------------------------------------------------"
echo "  WordPress     → http://${DOMAIN}:${WP_HTTP_PORT} (http://${PROD_DOMAIN}:${WP_HTTP_PORT})"
echo "  WordPress SSL → https://${DOMAIN}:${WP_HTTPS_PORT} (https://${PROD_DOMAIN}:${WP_HTTPS_PORT})"
echo "  phpMyAdmin    → http://${DOMAIN}:${PHPMYADMIN_PORT} (http://${PROD_DOMAIN}:${PHPMYADMIN_PORT})"
echo "------------------------------------------------------"
echo "  MYSQL_USER    → ${MYSQL_USER}"
echo "  MYSQL_PASS    → ${MYSQL_PASSWORD}"
echo "  WP DB User    → ${WORDPRESS_DB_USER}"
echo "  WP DB Pass    → ${WORDPRESS_DB_PASSWORD}"
echo "  Root MySQL    → ${MYSQL_ROOT_PASSWORD}"
echo "  PMA Root Pass → ${PMA_ROOT_PASSWORD}"
echo "------------------------------------------------------"

rm -rf db 
rm -rf data
# 3) Clean up old containers/volumes (if any)
docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" down -v || true

#  Stop and remove containers only (DO NOT remove volumes)
docker compose -p "$STACK_NAME" down


# 4) Deploy the stack with unique project name
docker compose --env-file "$STACK_ENV_FILE" -p "$STACK_NAME" up -d --force-recreate

