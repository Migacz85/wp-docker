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

# Install and configure plugins
echo "📦 Installing and configuring plugins..."
wp plugin install --activate --allow-root \
    wordfence \
    updraftplus \
    wp-mail-smtp

# Configure Wordfence
echo "🛡️ Configuring Wordfence..."
if [ -n "$WORDFENCE_KEY" ]; then
    wp option update wordfence_options "{\"key\":\"$WORDFENCE_KEY\"}" --format=json --allow-root
    
    # Set proper permissions for Wordfence
    WF_DIR="/var/www/html/wp-content/wflogs"
    mkdir -p "$WF_DIR"
    chown -R www-data:www-data "$WF_DIR"
    chmod -R 775 "$WF_DIR"
    
    # Rebuild WAF config
    wp eval 'wordfence::install();' --allow-root
    wp eval 'wordfence::startScan();' --allow-root
else
    echo "⚠️ Warning: WORDFENCE_KEY not set, skipping Wordfence configuration"
fi

# Set up permalinks
echo "🔗 Setting up permalinks..."
wp rewrite structure '/%postname%/' --allow-root
wp rewrite flush --allow-root

# Set timezone to Dublin
echo "⏰ Setting timezone to Dublin..."
wp option update timezone_string "Europe/Dublin" --allow-root

# Disable comments
echo "🚫 Disabling comments..."
wp option update default_comment_status closed --allow-root
wp option update default_ping_status closed --allow-root
wp option update default_pingback_flag closed --allow-root

# Print credentials
echo -e "\n🔑 WordPress Admin Credentials:"
echo "----------------------------------"
echo "URL: https://${DOMAIN}:${WP_HTTPS_PORT}/wp-admin"
echo "HTTP URL: http://${DOMAIN}:${WP_HTTP_PORT}/wp-admin"
echo "Username: admin"
echo "Password: changeme"
echo "----------------------------------"

echo "✅ Post-installation complete!"
