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

# Check if wp-cli is installed
if ! command -v wp &> /dev/null; then
    echo "🔧 Installing WP-CLI..."
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
    chmod +x wp-cli.phar
    mv wp-cli.phar /usr/local/bin/wp
    wp --info --allow-root
fi


CONFIG_PATH="/var/www/html/wp-config.php"
MAX_WAIT=300   # total time to wait in seconds
SLEEP_INTERVAL=5
TIME_WAITED=0

echo "⏳ Waiting for WordPress to generate wp-config.php..."

while [ ! -f "$CONFIG_PATH" ]; do
    if [ "$TIME_WAITED" -ge "$MAX_WAIT" ]; then
        echo "❌ Timeout reached: wp-config.php not found after $MAX_WAIT seconds."
        exit 1
    fi
    echo "⏳ Still waiting... (${TIME_WAITED}s elapsed)"
    sleep "$SLEEP_INTERVAL"
    TIME_WAITED=$((TIME_WAITED + SLEEP_INTERVAL))
done

sleep 15

echo "✅ wp-config.php found at $CONFIG_PATH — continuing."

# Print WordPress core version
WP_VERSION=$(wp core version --allow-root)
echo "ℹ️ WordPress Core Version: $WP_VERSION"

# Change to WordPress directory
cd /var/www/html

# Set default values if environment variables are not set
DOMAIN=${DOMAIN:-localhost}
WP_HTTPS_PORT=${WP_HTTPS_PORT:-443}
ADMIN_EMAIL=${ADMIN_EMAIL:-developers@matrixinternet.com}

# Check if WordPress is already installed
if ! wp core is-installed --allow-root; then
    echo "🔧 Installing WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN}:${WP_HTTPS_PORT}" \
        --title="My Matrix WordPress Site" \
        --admin_user="$ADMIN_USER" \
        --admin_password="$ADMIN_PASSWORD" \
        --admin_email="$ADMIN_EMAIL"
fi

# Update password and email for ADMIN_USER
if wp user get "$ADMIN_USER" --allow-root > /dev/null 2>&1; then
    echo "🔑 Updating admin user password and email..."
    wp user update "$ADMIN_USER" --user_pass="$ADMIN_PASSWORD" --user_email="$ADMIN_EMAIL" --allow-root
fi

# Print credentials
echo -e "\n🔑 WordPress Admin Credentials:"
echo "----------------------------------"
echo "HTTP URL: http://${DOMAIN}:${WP_HTTP_PORT}/wp-admin"
echo "HTTPS URL: https://${DOMAIN}:${WP_HTTPS_PORT}/wp-admin"
echo "Username: $ADMIN_USER"
echo "Password: $ADMIN_PASSWORD"
echo "Admin Email: $ADMIN_EMAIL"
echo "----------------------------------"

# Change theme to twentytwentyfour
#echo "🎨 Setting up theme..."
#wp theme install twentytwentyfour --activate --allow-root

# Install and configure plugins

# echo "📦 Installing and configuring plugins..."
# wp plugin install --activate --allow-root \
#     wordfence \
#     updraftplus \
#     wp-mail-smtp
# chown -R www-data:www-data wp-content/wflogs
# chmod -R 755 wp-content/wflogs
# chown -R www-data:www-data "$PLUGINS_DIR"
# chmod -R 775 "$PLUGINS_DIR"
chown -R www-data:www-data wp-content
chmod -R 775 wp-content

# Set proper permissions for plugins and Wordfence

# PLUGINS_DIR="/var/www/html/wp-content/plugins"
# WF_DIR="/var/www/html/wp-content/wflogs"
# mkdir -p "$WF_DIR"
# chown -R www-data:www-data "$WF_DIR"
# chmod -R 775 "$WF_DIR"
   

# # Set up permalinks
# echo "🔗 Setting up permalinks..."
# wp rewrite structure '/%postname%/' --allow-root
# wp rewrite flush --allow-root

# # Set timezone to Dublin
# echo "⏰ Setting timezone to Dublin..."
# wp option update timezone_string "Europe/Dublin" --allow-root

# # Disable comments
# echo "🚫 Disabling comments..."
# wp option update default_comment_status closed --allow-root
# wp option update default_ping_status closed --allow-root
# wp option update default_pingback_flag closed --allow-root


echo "✅ Post-installation complete!"
