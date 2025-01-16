ARG ALPINE_VERSION=3.21
FROM alpine:${ALPINE_VERSION}

# Cài đặt các gói cơ bản và php
RUN set -eux; \
    apk add --no-cache \
        bash \
        curl \
        php84 \
        php84-ctype \
        php84-curl \
        php84-dom \
        php84-fileinfo \
        php84-fpm \
        php84-gd \
        php84-intl \
        php84-mbstring \
        php84-mysqli \
        php84-opcache \
        php84-openssl \
        php84-phar \
        php84-session \
        php84-tokenizer \
        php84-xml \
        php84-xmlreader \
        php84-xmlwriter && \
    rm -rf /var/cache/apk/* /tmp/* /var/tmp/*

# Tạo user và group www-data
RUN set -eux; \
    addgroup -g 82 -S www-data; \
    adduser -u 82 -D -S -G www-data www-data

# Cài đặt WordPress
RUN set -eux; \
    mkdir -p /usr/src/wordpress; \
    curl -o wordpress.tar.gz -fL "https://wordpress.org/latest.tar.gz"; \
    tar -xzf wordpress.tar.gz -C /usr/src/; \
    rm wordpress.tar.gz; \
    \
    # Thiết lập thư mục WordPress
    mkdir -p /usr/src/wordpress/wp-content; \
    chown -R www-data:www-data /usr/src/wordpress; \
    chmod -R 755 /usr/src/wordpress; \
    \
    # Cài đặt WP-CLI
    curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
    chmod +x /usr/local/bin/wp

# Sao chép các file cấu hình
COPY --chown=www-data:www-data wp-config-docker.php /usr/src/wordpress/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

VOLUME /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
