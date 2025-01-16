# wordpress-wp-cli-php8.4-fpm-alpine-minial

Phiên bản [docker](https://hub.docker.com/r/bibica/wordpress-wp-cli-php8.4-fpm-alpine-minial) images php 8.4 được làm dựa theo bản gốc [php 8.3](https://github.com/docker-library/wordpress/blob/0015d465b4115ade0e0f98b3df8b5c17ec4a98e4/latest/php8.3/fpm-alpine/Dockerfile) từ WordPress
* Gỡ bỏ `imagemagick` và `ghostscript` vì không dùng
* Cài đặt thêm `WP-CLI`
* Dung lượng ~ 67.25 MB
* Duy trì trên 2 nền tảng thông dụng `amd64` và `arm64`
* Cập nhập 1 ngày 1 lần lúc 0h sáng theo giờ Việt Nam (UTC +7), đảm bảo luôn sử dụng các phiên bản mới nhất

``` php -v
PHP 8.4.2 (cli) (built: Jan  8 2025 19:12:14) (NTS)
Copyright (c) The PHP Group
Built by https://github.com/docker-library/php
Zend Engine v4.4.2, Copyright (c) Zend Technologies
    with Zend OPcache v8.4.2, Copyright (c), by Zend Technologies
```
```[PHP Modules]
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

[Zend Modules]
Zend OPcache
```
