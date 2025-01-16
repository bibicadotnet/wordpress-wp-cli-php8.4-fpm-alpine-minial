FROM php:8.4-fpm-alpine

# Cài đặt dependencies, cấu hình PHP và dọn dẹp trong cùng một layer
RUN set -eux; \
    # Cài đặt các dependencies
    apk add --no-cache --virtual .build-deps \
        freetype-dev \
        gcc \
        g++ \
        icu-dev \
        jpeg-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        libwebp-dev \
        libzip-dev \
        make \
        musl-dev \
        zlib-dev \
    && \
    apk add --no-cache \
        bash \
        freetype \
        icu-libs \
        libjpeg-turbo \
        libpng \
        libzip \
    && \
    # Cấu hình và cài đặt PHP extensions
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
    && \
    docker-php-ext-install -j$(nproc) \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        zip \
    && \
    # Cài đặt WP-CLI
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    \
    # Dọn dẹp build dependencies
    apk del .build-deps && \
    docker-php-source delete && \
    rm -rf \
        /tmp/* \
        /var/cache/apk/* \
        /usr/src/php.tar.xz \
        /usr/src/php.tar.xz.asc \
        /usr/local/php/man \
        /usr/local/include \
        /usr/local/lib/php/doc \
        /usr/local/lib/php/test \
        /usr/local/php/test \
        /usr/local/php/doc

# Cấu hình opcache
COPY --chmod=644 php.ini-production /usr/local/etc/php/php.ini
RUN set -eux; \
    docker-php-ext-enable opcache; \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'opcache.enable_cli=1'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Cấu hình error logging
RUN { \
        echo 'error_reporting = E_ERROR | E_WARNING | E_PARSE | E_CORE_ERROR | E_CORE_WARNING | E_COMPILE_ERROR | E_COMPILE_WARNING | E_RECOVERABLE_ERROR'; \
        echo 'display_errors = Off'; \
        echo 'display_startup_errors = Off'; \
        echo 'log_errors = On'; \
        echo 'error_log = /dev/stderr'; \
        echo 'log_errors_max_len = 1024'; \
        echo 'ignore_repeated_errors = On'; \
        echo 'ignore_repeated_source = Off'; \
        echo 'html_errors = Off'; \
    } > /usr/local/etc/php/conf.d/error-logging.ini

# Cài đặt WordPress và dọn dẹp trong cùng một layer
RUN set -eux; \
    curl -o wordpress.tar.gz -fL "https://wordpress.org/latest.tar.gz" && \
    tar -xzf wordpress.tar.gz -C /usr/src/ && \
    rm wordpress.tar.gz && \
    chown -R www-data:www-data /usr/src/wordpress && \
    mkdir -p /usr/src/wordpress/wp-content && \
    chmod -R 1777 /usr/src/wordpress/wp-content

VOLUME /var/www/html

COPY --chown=www-data:www-data wp-config-docker.php /usr/src/wordpress/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
