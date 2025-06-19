#!/bin/bash
set -e

echo "🚀 Running WordPress post-installation script..."

# Load environment variables from .env file
if [ -f /var/www/html/.env ]; then
    source /var/www/html/.env
else
    echo "⚠️ Warning: .env file not found in /var/www/html/"
    # Fallback to container environment variables
    source /etc/apache2/envvars
fi

# Wait for WordPress files to be ready
while [ ! -f /var/www/html/wp-config.php ]; do
    echo "⏳ Waiting for WordPress files to be ready..."
    sleep 30
done

# Change to WordPress directory
cd /var/www/html

# Set default values if environment variables are not set
DOMAIN=${DOMAIN:-localhost}
WP_HTTPS_PORT=${WP_HTTPS_PORT:-443}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-$(openssl rand -hex 16)}

# Check if WordPress is already installed
if ! wp core is-installed --allow-root; then
    echo "🔧 Installing WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN}:${WP_HTTPS_PORT}" \
        --title="My Matrix WordPress Site" \
        --admin_user="admin" \
        --admin_password="changeme" \
        --admin_email="marcin@matrixinternet.com"
fi

# Change theme to twentytwentyfour
echo "🎨 Setting up theme..."
wp theme install twentytwentyfour --activate --allow-root

# Print credentials
echo -e "\n🔑 WordPress Admin Credentials:"
echo "----------------------------------"
echo "URL: https://${DOMAIN}:${WP_HTTPS_PORT}/wp-admin"
echo "HTTP URL: http://${DOMAIN}:${WP_HTTP_PORT}/wp-admin"
echo "Username: admin
echo "Password: changeme 
echo "----------------------------------"

echo "✅ Post-installation complete!"
