#!/bin/bash
set -e

echo "🚀 Running WordPress post-installation script..."

# Wait for WordPress files to be ready
while [ ! -f /var/www/html/wp-config.php ]; do
    echo "⏳ Waiting for WordPress files to be ready..."
    sleep 15
done

# Change to WordPress directory
cd /var/www/html

# Check if WordPress is already installed
if ! wp core is-installed --allow-root; then
	wp core install --allow-root \
  --url="http://localhost:22188" \
  --title="My Site" \
  --admin_user="admin" \
  --admin_password="yourStrongPassword" \
  --admin_email="admin@example.com"

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
