#!/bin/bash
set -e

echo "Running WordPress post-installation script..."

apt update && apt install curl &&
wp theme install twentytwentyfour --activate --allow-root

curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

echo "Post-installation complete!"
