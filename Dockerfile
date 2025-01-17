FROM php:8.4-fpm-alpine

# Cài đặt bash và elfutils
RUN set -eux && \
    apk add --no-cache \
    bash && \

# Cài đặt các phần mở rộng PHP cần thiết
RUN set -ex && \
    apk add --no-cache --virtual .build-deps \
    $PHPIZE_DEPS \
    freetype-dev \
    icu-dev \
    libheif-dev \
    libavif-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev && \
    docker-php-ext-configure gd \
        --with-avif \
        --with-freetype \
        --with-jpeg \
        --with-webp && \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        zip && \
# Kiểm tra lỗi cài đặt
    out="$(php -r 'exit(0);')" && \
    [ -z "$out" ] && \
    err="$(php -r 'exit(0);' 3>&1 1>&2 2>&3)" && \
    [ -z "$err" ] && \
    extDir="$(php -r 'echo ini_get("extension_dir");')" && \
    [ -d "$extDir" ] && \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive "$extDir" \
        | tr ',' '\n' \
        | sort -u \
        | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )" && \
    apk add --no-network --virtual .wordpress-phpexts-rundeps $runDeps && \
    apk del --no-network .build-deps && \
    ! { ldd "$extDir"/*.so | grep 'not found'; } && \
    err="$(php --version 3>&1 1>&2 2>&3)" && \
    [ -z "$err" ]

# Thiết lập PHP.ini
RUN set -eux && \
    docker-php-ext-enable opcache && \
    { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
    } > /usr/local/etc/php/conf.d/opcache-recommended.ini && \

# Cài đặt logging
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
} > /usr/local/etc/php/conf.d/error-logging.ini && \

# Cài đặt WordPress
RUN set -eux && \
    curl -o wordpress.tar.gz -fL "https://wordpress.org/latest.tar.gz"&& \
    tar -xzf wordpress.tar.gz -C /usr/src/&& \
    rm wordpress.tar.gz \
    # Thêm file .htaccess
    [ ! -e /usr/src/wordpress/.htaccess ] && \
    { \
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
    chown -R www-data:www-data /usr/src/wordpress && \
    mkdir wp-content && \
    for dir in /usr/src/wordpress/wp-content/*/ cache; do \
        dir="$(basename "${dir%/}")" && \
        mkdir "wp-content/$dir" && \
    done && \
    chown -R www-data:www-data wp-content && \
    chmod -R 1777 wp-content

VOLUME /var/www/html

COPY --chown=www-data:www-data wp-config-docker.php /usr/src/wordpress/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
