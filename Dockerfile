# Build stage
FROM php:8.4-fpm-alpine as builder

# Cài đặt build dependencies
RUN set -eux; \
    apk add --no-cache \
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
        zlib-dev

# Cấu hình và build PHP extensions
RUN docker-php-ext-configure gd \
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
        zip

# Final stage
FROM php:8.4-fpm-alpine

# Cài đặt runtime dependencies
RUN apk add --no-cache \
        bash \
        freetype \
        icu-libs \
        libjpeg-turbo \
        libpng \
        libzip

# Copy built extensions và enable chúng
COPY --from=builder /usr/local/lib/php/extensions /usr/local/lib/php/extensions
RUN docker-php-ext-enable \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        zip

# Kiểm tra PHP extensions và cài đặt runtime dependencies
RUN set -eux; \
    # Kiểm tra PHP startup
    out="$(php -r 'exit(0);')"; \
    [ -z "$out" ]; \
    err="$(php -r 'exit(0);' 3>&1 1>&2 2>&3)"; \
    [ -z "$err" ]; \
    \
    extDir="$(php -r 'echo ini_get("extension_dir");')"; \
    [ -d "$extDir" ]; \
    # Quét và cài đặt các runtime dependencies cần thiết
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive "$extDir" \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache --virtual .wordpress-phpexts-rundeps $runDeps; \
    \
    # Kiểm tra các shared libraries
    ! { ldd "$extDir"/*.so | grep 'not found'; }; \
    # Kiểm tra PHP startup errors
    err="$(php --version 3>&1 1>&2 2>&3)"; \
    [ -z "$err" ]

# Cài đặt WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Cấu hình opcache
RUN set -eux; \
    docker-php-ext-enable opcache; \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
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

# Cài đặt WordPress
RUN set -eux; \
    curl -o wordpress.tar.gz -fL "https://wordpress.org/latest.tar.gz"; \
    tar -xzf wordpress.tar.gz -C /usr/src/; \
    rm wordpress.tar.gz; \
    chown -R www-data:www-data /usr/src/wordpress; \
    cd /usr/src/wordpress && \
    mkdir -p wp-content; \
    for dir in /usr/src/wordpress/wp-content/*/ cache; do \
        dir="$(basename "${dir%/}")"; \
        mkdir -p "wp-content/$dir"; \
    done; \
    chown -R www-data:www-data wp-content; \
    chmod -R 1777 wp-content

VOLUME /var/www/html

COPY --chown=www-data:www-data wp-config-docker.php /usr/src/wordpress/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
