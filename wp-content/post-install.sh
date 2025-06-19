#!/bin/bash
set -e

echo "🚀 Running WordPress post-installation script..."

# Change to WordPress directory
cd /var/www/html

# Install WP-CLI if not present
if ! command -v wp &> /dev/null; then
    echo "📦 Installing WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
fi

# Check if WordPress is already installed
if ! wp core is-installed --allow-root; then
    echo "🔧 Installing WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN}:${WP_HTTPS_PORT}" \
        --title="My Matrix WordPress Site" \
        --admin_user=admin \
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
