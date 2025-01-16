# wordpress-wp-cli-php8.4-fpm-alpine

## Introduction

* A personal version, while waiting for the official WordPress release to support PHP 8.4.

PHP8.4 update for [Docker-LCMP-Multisite](https://github.com/bibicadotnet/Docker-LCMP-Multisite-WordPress-Minimal)
```
docker pull bibica/wordpress-wp-cli-php8.4-fpm-alpine:latest
```
It’s unclear why WordPress has not released an official image for PHP 8.4, so I created a version based on the [Dockerfile](https://github.com/docker-library/wordpress/blob/0015d465b4115ade0e0f98b3df8b5c17ec4a98e4/latest/php8.3/fpm-alpine/Dockerfile) structure from WordPress.

## Features

- Uses [docker-php-extension-installer](https://github.com/mlocati/docker-php-extension-installer) to install extensions .
- Keeps all extensions as in the original and adds `WP-CLI`.
- Supports two common platforms: `amd64` and `arm64`.
- Updated once a day at 12:00 AM Vietnam time (UTC +7), ensuring the use of the latest versions.

```
PHP 8.4.2 (cli) (built: Jan  8 2025 19:12:14) (NTS)
Copyright (c) The PHP Group
Built by https://github.com/docker-library/php
Zend Engine v4.4.2, Copyright (c) Zend Technologies
    with Zend OPcache v8.4.2, Copyright (c), by Zend Technologies
```
```
[PHP Modules]
bcmath
Core
ctype
curl
date
dom
exif
fileinfo
filter
gd
hash
iconv
imagick
intl
json
libxml
mbstring
mysqli
mysqlnd
openssl
pcre
PDO
pdo_sqlite
Phar
posix
random
readline
Reflection
session
SimpleXML
sodium
SPL
sqlite3
standard
tokenizer
xml
xmlreader
xmlwriter
Zend OPcache
zip
zlib
```
