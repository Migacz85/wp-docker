#!/bin/bash
set -e

echo "🚀 Running WordPress post-installation script..."

# Load environment variables from container
source /etc/apache2/envvars

# Wait for WordPress files to be ready
while [ ! -f /var/www/html/wp-config.php ]; do
    echo "⏳ Waiting for WordPress files to be ready..."
    sleep 15
done

# Change to WordPress directory
cd /var/www/html

# Check if WordPress is already installed
if ! wp core is-installed --allow-root; then
    echo "🔧 Installing WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN}:${WP_HTTPS_PORT}" \
        --title="My Matrix WordPress Site" \
        --admin_user="admin" \
        --admin_password="${MYSQL_ROOT_PASSWORD}" \
        --admin_email="admin@${DOMAIN}"
fi

# Change theme to twentytwentyfour
echo "🎨 Setting up theme..."
wp theme install twentytwentyfour --activate --allow-root

# Print credentials
echo -e "\n🔑 WordPress Admin Credentials:"
echo "----------------------------------"
echo "URL: https://${DOMAIN}:${WP_HTTPS_PORT}/wp-admin"
echo "Username: admin"
echo "Password: ${MYSQL_ROOT_PASSWORD}"
echo "----------------------------------"

echo "✅ Post-installation complete!"
