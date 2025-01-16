# wordpress-wp-cli-php8.4-fpm-alpine-minial

Phiên bản docker images php 8.4 được làm dựa theo bản gốc [php 8.3](https://github.com/docker-library/wordpress/blob/0015d465b4115ade0e0f98b3df8b5c17ec4a98e4/latest/php8.3/fpm-alpine/Dockerfile) từ WordPress
* Gỡ bỏ `imagemagick` và `ghostscript` vì không dùng
* Cài đặt thêm `WP-CLI`
* Dung lượng ~ 67.25 MB
* Duy trì trên 2 nền tảng thông dụng `amd64` và `arm64`
* Cập nhập 1 ngày 1 lần lúc 0h sáng theo giờ Việt Nam (UTC +7), đảm bảo luôn sử dụng các phiên bản mới nhất
