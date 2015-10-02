FROM debian:wheezy

MAINTAINER Leonid Makarov <leonid.makarov@blinkreaction.com>

# Prevent services autoload (http://jpetazzo.github.io/2013/10/06/policy-rc-d-do-not-start-services-automatically/)
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Enabling additional repos
RUN sed -i 's/main/main contrib non-free/' /etc/apt/sources.list

# Basic packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    curl \
    wget \
    zip \
    git \
    mysql-client \
    pv \
    openssh-client \
    rsync \
    ca-certificates \
    apt-transport-https \
    locales \
    mc \
    supervisor \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set timezone and locale.
RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8
ENV LC_ALL C.UTF-8

# Add Dotdeb PHP5.6 repo
RUN curl -sSL http://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
    echo 'deb http://packages.dotdeb.org wheezy-php56 all' > /etc/apt/sources.list.d/dotdeb.list && \
    echo 'deb-src http://packages.dotdeb.org wheezy-php56 all' >> /etc/apt/sources.list.d/dotdeb.list

# PHP packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    php5-common \
    php5-cli \
    php-pear \
    php5-mysql \
    php5-imagick \
    php5-mcrypt \
    php5-curl \
    php5-gd \
    php5-sqlite \
    php5-json \
    php5-intl \
    php5-fpm \
    php5-memcache \
    php5-xdebug \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Composer
RUN curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ENV PATH /root/.composer/vendor/bin:$PATH

RUN \
    # Drush 6,7 (default),8
    composer global require drush/drush:7.* && \
    mkdir /root/drush6 && cd /root/drush6 && composer require drush/drush:6.* && \
    mkdir /root/drush8 && cd /root/drush8 && composer require drush/drush:dev-master --prefer-dist && \
    echo "alias drush6='/root/drush6/vendor/bin/drush'" >> /root/.bashrc && \
    echo "alias drush7='/root/.composer/vendor/bin/drush'" >> /root/.bashrc && \
    echo "alias drush8='/root/drush8/vendor/bin/drush'" >> /root/.bashrc && \
    # Drupal Console
    curl -sSL http://drupalconsole.com/installer | php && \
    mv console.phar /usr/local/bin/drupal && \
    # Drush modules
    drush dl registry_rebuild

## PHP settings
RUN mkdir -p /var/www/docroot && \
    # PHP-FPM settings
    sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php5/fpm/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php5/fpm/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 500M/' /etc/php5/fpm/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 500M/' /etc/php5/fpm/php.ini && \
    sed -i '/error_log = php_errors.log/c\error_log = \/dev\/stdout/' /etc/php5/fpm/php.ini && \
    sed -i '/listen = /c\listen = 0.0.0.0:9000' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/listen.allowed_clients/c\;listen.allowed_clients =' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/;daemonize = yes/c\daemonize = no' /etc/php5/fpm/php-fpm.conf && \
    sed -i '/;catch_workers_output/c\catch_workers_output = yes' /etc/php5/fpm/php-fpm.conf && \
    # PHP CLI settings
    sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php5/cli/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 600/' /etc/php5/cli/php.ini && \
    sed -i '/error_log = php_errors.log/c\error_log = \/dev\/stdout/' /etc/php5/cli/php.ini && \
    # PHP module settings
    echo 'opcache.memory_consumption=128' >> /etc/php5/mods-available/opcache.ini

COPY config/php5/xdebug.ini /etc/php5/mods-available/xdebug.ini

# Adding NodeJS repo (for up-to-date versions)
# This command is a stripped down version of "curl --silent --location https://deb.nodesource.com/setup_0.12 | bash -"
RUN curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_0.12 wheezy main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_0.12 wheezy main' >> /etc/apt/sources.list.d/nodesource.list

# Other language packages and dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    ruby1.9.1-full \
    rlwrap \
    make \
    gcc \
    nodejs \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Bundler
RUN gem install bundler

# Home directory for bundle installs
ENV BUNDLE_PATH .bundler

# Grunt, Bower
RUN npm install -g grunt-cli bower

WORKDIR /var/www

# Copy configs and scripts
COPY config/.ssh /root/.ssh
COPY config/.drush /root/.drush
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY startup.sh /opt/startup.sh

EXPOSE 9000

# Set TERM so text editors/etc. can be used
ENV TERM xterm

# Default SSH key name
ENV SSH_KEY_NAME id_rsa

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD /usr/bin/supervisord -n
