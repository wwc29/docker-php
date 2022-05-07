FROM php:7.4-fpm-buster

COPY etc/sources.list /etc/apt/sources.list

RUN apt-get update -y

RUN apt-get install -y libzip-dev zip \
    && docker-php-ext-configure zip \
	&& docker-php-ext-install zip

RUN docker-php-ext-install -j$(nproc) \
    bcmath \
    calendar \
    pcntl \
    pdo_mysql

# start GD库相关
RUN apt-get install -y sendmail zlib1g-dev libwebp-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libfreetype6-dev

RUN docker-php-ext-configure gd --with-freetype --with-jpeg

RUN docker-php-ext-install gd
# end DG库相关

RUN docker-php-ext-install opcache sockets

RUN pecl install redis \
    && docker-php-ext-enable redis

# nginx start
RUN apt-get install -y nginx
RUN rm -f /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
COPY nginx/enable-php.conf /etc/nginx/enable-php.conf
COPY nginx/site.conf /etc/nginx/conf.d/site.conf
#nginx end

# composer start
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && php composer-setup.php \
    && php -r "unlink('composer-setup.php');"\
    && mv composer.phar /usr/local/bin/composer \
    && chmod +x /usr/local/bin/composer
# composer end

# swoole start
ENV swoole_src=swoole-src-4.7.1
RUN apt-get install -y wget openssl libssl-dev libcurl4-openssl-dev
COPY thirdparty/${swoole_src}.tar.gz /tmp/
RUN cd /tmp \
    && tar zxf ${swoole_src}.tar.gz && rm -f ${swoole_src}.tar.gz \
    && cd ${swoole_src} \
    && phpize && ./configure --enable-http2 --enable-openssl --enable-swoole-curl \
    && make && make install \
    && rm -rf /tmp/${swoole_src} \
    && docker-php-ext-enable swoole
# swoole end

# xlswriter start
ENV XLSWRITER_NAME=xlswriter-1.3.7.tgz
COPY thirdparty/${XLSWRITER_NAME} /tmp
RUN cd /tmp \
    && mkdir -p /tmp/xlswriter \
    && tar -xf ${XLSWRITER_NAME} -C /tmp/xlswriter --strip-components=1 \
    && rm ${XLSWRITER_NAME} \
    && cd /tmp/xlswriter \
    && phpize && ./configure --enable-reader && make && make install
RUN docker-php-ext-enable xlswriter
# xlswriter end

RUN apt-get install -y wget libssh2-1-dev
RUN pecl install ssh2-1.2 \
    && docker-php-ext-enable ssh2

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN rm -f /usr/local/etc/php-fpm.d/zz-docker.conf

COPY entrypoint.sh /etc/entrypoint.sh
RUN chmod +x /etc/entrypoint.sh
ENTRYPOINT ["/etc/entrypoint.sh"]

COPY html /var/www/html
COPY php/conf.d/docker-php-ext-opcache.ini /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini

RUN echo "* soft nofile 655360" >> /etc/security/limits.conf \
    && echo "* hard nofile 655360" >> /etc/security/limits.conf

RUN mkdir -p /var/log/php \
    && chown -R www-data:www-data /var/log/php
COPY php/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf
COPY php/php-fpm.conf /usr/local/etc/php-fpm.conf

STOPSIGNAL SIGQUIT
EXPOSE 80
CMD ["php-fpm", "-F"]

RUN sed -i 's/expose_php = On/expose_php = Off/g' "$PHP_INI_DIR/php.ini" \
    && sed -i 's/# server_tokens off/server_tokens off/g' /etc/nginx/nginx.conf
