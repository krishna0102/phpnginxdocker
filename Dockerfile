FROM php:fpm
RUN apt-get update
RUN apt-get upgrade -y
RUN apt-get install -y --fix-missing \
    apt-utils \
    gnupg
RUN apt-get install -y --no-install-recommends \
    iputils-ping \
    libicu-dev \
    libmemcached-dev \
    libz-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
    libmcrypt-dev \
    libxml2-dev \
    libbz2-dev \
    libjpeg62-turbo-dev \
    librabbitmq-dev \
    libzip-dev \
    libonig-dev \
    libxpm-dev \    
    curl \
    git \
    subversion \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install various PHP extensions
RUN docker-php-ext-configure bcmath --enable-bcmath \
  && docker-php-ext-configure pcntl --enable-pcntl \
  && docker-php-ext-configure pdo_mysql --with-pdo-mysql \
  && docker-php-ext-configure mbstring --enable-mbstring \
  && docker-php-ext-configure soap --enable-soap \
  && docker-php-ext-install \
    bcmath \
    intl \
    mbstring \
    mysqli \
    pcntl \
    pdo_mysql \
    pdo_pgsql \
    soap \
    sockets \
    zip \
  && docker-php-ext-install opcache \
  && docker-php-ext-enable opcache \
  && pecl install amqp \
  && docker-php-ext-enable amqp


# Copy opcache configration
COPY ./opcache.ini /usr/local/etc/php/conf.d/opcache.ini

# Copy timezone configration
COPY ./timezone.ini /usr/local/etc/php/conf.d/timezone.ini

# Set timezone
RUN rm /etc/localtime \
  && ln -s /usr/share/zoneinfo/Asia/Kolkata /etc/localtime \
  && "date"


# Short open tags fix - another Symfony requirements
COPY ./custom-php.ini /usr/local/etc/php/conf.d/custom-php.ini

# Composer
ENV COMPOSER_HOME /var/www/.composer

RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/bin \
    --filename=composer \
  && composer self-update

RUN chown -R www-data:www-data /var/www/ \
  && mkdir -p $COMPOSER_HOME/cache \
  && composer global require "hirak/prestissimo:^0.3" \
  && rm -rf $COMPOSER_HOME/cache \
  && mkdir -p $COMPOSER_HOME/cache

# Clean up
RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME $COMPOSER_HOME

RUN chown -R www-data:www-data /var/www/html

# Expose and start PHP-FPM
EXPOSE 9000
CMD ["php-fpm"]


FROM nginx:stable

EXPOSE 8080
EXPOSE 443

COPY ./conf.d/site.conf /etc/nginx/conf.d/default.conf
COPY ./www/ /var/www/html/

# RUN chown -R www-data:www-data /var/www/html