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
    fileinfo \
    bcmath \
    calendar \
    pcntl \
    pdo_mysql \
    mbstring

RUN pecl install redis yaconf \
    && docker-php-ext-enable redis yaconf

# start GD库相关
RUN apt-get install -y sendmail zlib1g-dev libwebp-dev libjpeg62-turbo-dev libpng-dev libxpm-dev libfreetype6-dev

RUN docker-php-ext-configure gd --with-gd --with-webp-dir --with-jpeg-dir --with-png-dir --with-zlib-dir \
    --with-xpm-dir --with-freetype-dir

RUN docker-php-ext-install gd
# end DG库相关

RUN docker-php-ext-install opcache
