FROM wordpress:6.8.0-php8.2

# Add build argument for domain
ARG DOMAIN=localhost

# Enable SSL and configure Apache
RUN a2enmod ssl && \
    echo '<VirtualHost *:443>
        ServerName '"$DOMAIN"'
        DocumentRoot /var/www/html
        SSLEngine on
        SSLCertificateFile /etc/ssl/certs/portainer.crt
        SSLCertificateKeyFile /etc/ssl/private/portainer.key
        <Directory /var/www/html>
            AllowOverride All
            Require all granted
        </Directory>
    </VirtualHost>' > /etc/apache2/sites-available/default-ssl.conf && \
    a2ensite default-ssl

# Run post-install script before starting Apache
ENTRYPOINT ["/bin/sh", "-c", "/var/www/html/wp-content/post-install.sh && docker-entrypoint.sh apache2-foreground"]
