#!/bin/bash
set -euo pipefail

# Kiểm tra và copy WordPress files nếu cần
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "WordPress not found in /var/www/html - copying now..."
    
    # Copy WordPress core
    if [ "$(ls -A /var/www/html)" ]; then
        echo "WARNING: /var/www/html is not empty - copying anyhow"
    fi
    
    cp -r /usr/src/wordpress/* /var/www/html/
    
    # Copy wp-config.php
    if [ -f /usr/src/wordpress/wp-config-docker.php ]; then
        cp /usr/src/wordpress/wp-config-docker.php /var/www/html/wp-config.php
    fi
    
    echo "Complete! WordPress has been successfully copied to /var/www/html"
fi

# Ensure correct ownership
chown -R www-data:www-data /var/www/html

# First arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

exec "$@"
