#!/bin/bash
set -e

echo "Running WordPress post-installation script..."

wp theme install twentytwentyfour --activate --allow-root


echo "Post-installation complete!"
