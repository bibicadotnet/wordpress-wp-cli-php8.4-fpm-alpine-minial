# Stage 1: Build stage
FROM php:8.4-fpm-alpine AS build

# Cài đặt công cụ cần thiết để build PHP extensions
RUN set -eux; \
    apk add --no-cache \
        bash \
        freetype-dev \
        gcc \
        g++ \
        icu-dev \
        jpeg-dev \
        libpng-dev \
        libwebp-dev \
        libzip-dev \
        make \
        musl-dev \
        zlib-dev && \
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp && \
    docker-php-ext-install -j$(nproc) \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        zip && \
    docker-php-ext-enable opcache

# Cài đặt WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Kiểm tra PHP extensions và runtime dependencies
RUN set -eux; \
    out="$(php -r 'exit(0);')"; \
    [ -z "$out" ]; \
    err="$(php -r 'exit(0);' 3>&1 1>&2 2>&3)"; \
    [ -z "$err" ]; \
    extDir="$(php -r 'echo ini_get("extension_dir");')"; \
    [ -d "$extDir" ]; \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive "$extDir" \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-cache --virtual .wordpress-phpexts-rundeps $runDeps; \
    ! { ldd "$extDir"/*.so | grep 'not found'; }; \
    err="$(php --version 3>&1 1>&2 2>&3)"; \
    [ -z "$err" ];

# Cài đặt WordPress
RUN curl -o wordpress.tar.gz -fL "https://wordpress.org/latest.tar.gz" && \
    tar -xzf wordpress.tar.gz -C /usr/src/ && \
    rm wordpress.tar.gz && \
    chown -R www-data:www-data /usr/src/wordpress

# Tạo htaccess mặc định cho WordPress
RUN { \
        echo '# BEGIN WordPress'; \
        echo ''; \
        echo 'RewriteEngine On'; \
        echo 'RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]'; \
        echo 'RewriteBase /'; \
        echo 'RewriteRule ^index\.php$ - [L]'; \
        echo 'RewriteCond %{REQUEST_FILENAME} !-f'; \
        echo 'RewriteCond %{REQUEST_FILENAME} !-d'; \
        echo 'RewriteRule . /index.php [L]'; \
        echo ''; \
        echo '# END WordPress'; \
    } > /usr/src/wordpress/.htaccess && \
    mkdir -p /usr/src/wordpress/wp-content/cache && \
    chown -R www-data:www-data /usr/src/wordpress && \
    chmod -R 755 /usr/src/wordpress && \
    chmod -R 1777 /usr/src/wordpress/wp-content

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

# Sao chép docker-entrypoint.sh và cấp quyền thực thi
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Stage 2: Final image
FROM php:8.4-fpm-alpine

# Sao chép từ build stage
COPY --from=build /usr/local/etc/php/conf.d /usr/local/etc/php/conf.d
COPY --from=build /usr/local/bin/wp /usr/local/bin/wp
COPY --from=build /usr/src/wordpress /usr/src/wordpress

# Sao chép docker-entrypoint.sh từ build stage
COPY --from=build /usr/local/bin/docker-entrypoint.sh /usr/local/bin/

# Cài đặt runtime dependencies
RUN set -eux; \
    apk add --no-cache \
        bash \
        freetype \
        icu \
        jpeg \
        libpng \
        libwebp \
        libzip \
        zlib

# Khai báo volumes
VOLUME /var/www/html

# ENTRYPOINT và CMD
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
