#!/bin/bash
set -e

echo "Running WordPress post-installation script..."

# Wait for database to be ready
while ! mysqladmin ping -h"db" --silent; do
    echo "Waiting for database..."
    sleep 2
done

# Install WordPress if not already installed
if ! wp core is-installed; then
    echo "Installing WordPress..."
    wp core install \
        --url="https://${DOMAIN}:${WP_HTTPS_PORT}" \
        --title="My WordPress Site" \
        --admin_user="admin" \
        --admin_password="${MYSQL_PASSWORD}" \
        --admin_email="admin@${DOMAIN}" \
        --skip-email
fi

# Install and activate Akismet
if ! wp plugin is-installed akismet; then
    echo "Installing Akismet plugin..."
    wp plugin install akismet --activate
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html/wp-content

echo "Post-installation complete!"
