FROM php:7.3-fpm-stretch

RUN cat /etc/apt/sources.list
RUN cat > /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/debian-security stretch/updates main" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/debian-security stretch/updates main" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib" >> /etc/apt/sources.list \
    && echo "deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib" >> /etc/apt/sources.list \
    && echo "deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib" >> /etc/apt/sources.list

RUN apt-get update -y

RUN apt-get install -y libzip-dev zip \
    && docker-php-ext-configure zip --with-libzip \
	&& docker-php-ext-install zip

RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    calendar \
    pcntl \
    pdo_mysql

RUN pecl install redis yaconf \
    && docker-php-ext-enable redis yaconf

# start GD库相关
RUN apt-get install -y sendmail zlib1g-dev libwebp-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libfreetype6-dev

RUN docker-php-ext-configure gd --with-gd --with-webp-dir --with-jpeg-dir --with-png-dir --with-zlib-dir \
    --with-xpm-dir --with-freetype-dir

RUN docker-php-ext-install gd
# end DG库相关

RUN docker-php-ext-install opcache

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');"\
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# nginx start
RUN apt-get install -y nginx
RUN rm -f /etc/nginx/sites-available/default
COPY nginx/enable-php.conf /etc/nginx/enable-php.conf
COPY nginx/site.conf /etc/nginx/conf.d/site.conf
#nginx end

RUN rm -f /usr/local/etc/php-fpm.d/zz-docker.conf

COPY entrypoint.sh /etc/entrypoint.sh
ENTRYPOINT ["/etc/entrypoint.sh"]

COPY html /var/www/html

COPY php/conf.d/docker-php-ext-opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

STOPSIGNAL SIGQUIT
EXPOSE 80
CMD ["php-fpm", "-F"]
