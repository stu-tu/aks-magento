# sudo DOCKER_BUILDKIT=1 docker build -f k8s/src/Dockerfile -t silkewing/cheetah:dev-release .
FROM php:8.1-fpm as base

ENV COMPOSER_HOME=/tmp/composer
ENV APCU_VERSION=5.1.21

RUN apt-get update && apt-get install -y --no-install-recommends gnupg \
    nginx \
    netcat-traditional \
    libicu-dev \
    libfreetype6-dev \
    libjpeg-dev \
    libpng-dev \
    libsodium-dev \
    libxml2-dev \
    libxslt-dev \
    libzip-dev \
    rsync \
    supervisor \
    unzip \
    bash \
    wget \
    mariadb-client \
    vim \
    git \
    procps \
    ;

RUN pecl install apcu-${APCU_VERSION}

RUN docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg
RUN docker-php-ext-install -j "$(nproc)" \
    bcmath \
    gd \
    intl \
    mysqli \
    opcache \
    pdo_mysql \
    sockets \
    soap \
    xsl \
    zip \
    ;

RUN docker-php-ext-enable apcu

RUN echo "memory_limit=1G" >> /usr/local/etc/php/conf.d/zz-memory-limit-php.ini
RUN echo "apc.enable=1" >> /usr/local/etc/php/conf.d/zz-apcu.ini
RUN echo "apc.enable_cli=1" >> /usr/local/etc/php/conf.d/zz-apcu.ini
RUN echo "opcache.memory_consumption=512MB" >> /usr/local/etc/php/conf.d/zz-opcache.conf
RUN echo "opcache.max_accelerated_files=60000" >> /usr/local/etc/php/conf.d/zz-opcache.conf
RUN echo "opcache.consistency_checks=0" >> /usr/local/etc/php/conf.d/zz-opcache.conf
RUN echo "opcache.validate_timestamps=0" >> /usr/local/etc/php/conf.d/zz-opcache.conf
RUN echo "opcache.enable_cli=1" >> /usr/local/etc/php/conf.d/zz-opcache.conf

RUN mkdir -p /var/lib/nginx/{body,fastcgi} && \
    chown -R www-data:www-data /var/lib/nginx

RUN touch /run/nginx.pid && \
    chown www-data:www-data /run/nginx.pid

# Install NewRelic
ARG NEWRELIC_KEY="FAKE_KEY_REPLACE_WITH_REAL_KEY"
ARG NEWRELIC_APPNAME="EWING CHEETAH"

RUN \
  curl -L https://download.newrelic.com/php_agent/release/newrelic-php5-10.13.0.2-linux.tar.gz | tar -C /tmp -zx && \
  export NR_INSTALL_USE_CP_NOT_LN=1 && \
  export NR_INSTALL_SILENT=1 && \
  /tmp/newrelic-php5-*/newrelic-install install && \
  rm -rf /tmp/newrelic-php5-* /tmp/nrinstall* && \
  chown -R www-data:www-data /var/log/newrelic/ &&\
  sed -i \
    -e "s/\"REPLACE_WITH_REAL_KEY\"/$NEWRELIC_KEY/g" \
    -e "s/newrelic.appname = \"PHP Application\"/newrelic.appname = $NEWRELIC_APPNAME/g" \
    -e 's/;newrelic.daemon.app_connect_timeout =.*/newrelic.daemon.app_connect_timeout=15s/g' \
    -e 's/;newrelic.daemon.start_timeout =.*/newrelic.daemon.start_timeout=5s/g' \
    /usr/local/etc/php/conf.d/newrelic.ini
      
FROM base as build

COPY k8s/src/etc/supervisord.conf /etc/supervisor/supervisord.conf
COPY k8s/src/etc/nginx /etc/nginx

RUN curl https://files.magerun.net/n98-magerun2.phar -o /usr/local/bin/magerun \
    && chmod 755 /usr/local/bin/magerun

RUN mkdir -p /var/log/supervisor \
    && chown www-data:www-data /var/log/supervisor

COPY k8s/src/bin/entrypoint.sh /usr/local/bin/docker-php-entrypoint
RUN chmod 755 /usr/local/bin/docker-php-entrypoint

USER www-data
WORKDIR /var/www/html

# ARG COMPOSER_AUTH
COPY --chown=www-data auth.json auth.json

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

COPY --chown=www-data composer.json composer.json
COPY --chown=www-data composer.lock composer.lock

RUN php -d memory_limit=2G $(which composer) install --no-progress --no-dev

# COPY --chown=www-data app/etc/config.php app/etc/config.php
# ARG CACHEBUST=1
COPY --chown=www-data k8s/src/bin bin
RUN chmod -R 755 bin

COPY --chown=www-data app/code app/code
COPY --chown=www-data app/design app/design
COPY --chown=www-data scripts scripts
COPY --chown=www-data pwa pwa
COPY --chown=www-data m2-hotfixes m2-hotfixes

EXPOSE 8080

FROM build as app

COPY --chown=www-data app/etc/config.php app/etc/config.php.orig
# COPY --chown=www-data k8s/src/app/etc/website_scopes.ini app/etc/website_scopes.ini
# RUN tac app/etc/config.php | awk '!NF {print ""};NF {if (n) {print} else {n=1}}' | tac > app/etc/config.php
# RUN cat app/etc/website_scopes.ini >> app/etc/config.php
RUN awk 'NR==1,/\]/{sub(/\]/, "],\047scopes\047 => [\047websites\047 => [\047admin\047 => [\047website_id\047 => \0470\047,\047code\047 => \047admin\047,\047name\047 => \047Admin\047,\047sort_order\047 => \0470\047,\047default_group_id\047 => \0470\047,\047is_default\047 => \0470\047,],\047base\047 => [\047website_id\047 => \0471\047,\047code\047 => \047base\047,\047name\047 => \047Main Website\047,\047sort_order\047 => \0470\047,\047default_group_id\047 => \0471\047,\047is_default\047 => \0471\047,],],\047groups\047 => [0 => [\047group_id\047 => \0470\047,\047website_id\047 => \0470\047,\047name\047 => \047Default\047,\047root_category_id\047 => \0470\047,\047default_store_id\047 => \0470\047,\047code\047 => \047default\047,],1 => [\047group_id\047 => \0471\047,\047website_id\047 => \0471\047,\047name\047 => \047Main Website Store\047,\047root_category_id\047 => \0472\047,\047default_store_id\047 => \0471\047,\047code\047 => \047main_website_store\047,],],\047stores\047 => [\047admin\047 => [\047store_id\047 => \0470\047,\047code\047 => \047admin\047,\047website_id\047 => \0470\047,\047group_id\047 => \0470\047,\047name\047 => \047Admin\047,\047sort_order\047 => \0470\047,\047is_active\047 => \0471\047,],\047default\047 => [\047store_id\047 => \0471\047,\047code\047 => \047default\047,\047website_id\047 => \0471\047,\047group_id\047 => \0471\047,\047name\047 => \047Default Store View\047,\047sort_order\047 => \0470\047,\047is_active\047 => \0471\047,],],]")} 1' app/etc/config.php.orig > app/etc/config.php
# RUN cat /var/www/html/app/etc/config.php.orig
# RUN cat /var/www/html/app/etc/config.php
ENV MAGE_MODE=production
# Apply patches
RUN git apply m2-hotfixes/*.patch
RUN php -d memory_limit=2G bin/magento setup:di:compile
RUN composer dump-autoload --optimize --apcu
RUN php -d memory_limit=2G bin/magento setup:static-content:deploy -f
RUN rm -rf /var/www/html/var/cache
RUN rm -rf /var/www/html/var/page_cache
RUN rm -rf /var/www/html/var/session

COPY --chown=www-data app/etc/config.php app/etc/config.php
COPY --chown=www-data k8s/src/app/etc/env.docker.php app/etc/env.php
