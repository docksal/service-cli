FROM blinkreaction/drupal-base:jessie

MAINTAINER Leonid Makarov <leonid.makarov@blinkreaction.com>

# Basic packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    zip unzip \
    git \
    mysql-client \
    imagemagick \
    pv \
    openssh-client \
    rsync \
    apt-transport-https \
    sudo \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
    # Create a non-root user with access to sudo and the default group set to 'users' (gid = 100)
    useradd -m -s /bin/bash -g users -G sudo -p docker docker && \
    echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

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

## PHP settings
RUN mkdir -p /var/www/docroot && \
    # PHP-FPM settings
    sed -i '/memory_limit = /c memory_limit = 256M' /etc/php5/fpm/php.ini && \
    sed -i '/max_execution_time = /c max_execution_time = 300' /etc/php5/fpm/php.ini && \
    sed -i '/upload_max_filesize = /c upload_max_filesize = 500M' /etc/php5/fpm/php.ini && \
    sed -i '/post_max_size = /c post_max_size = 500M' /etc/php5/fpm/php.ini && \
    sed -i '/error_log = php_errors.log/c error_log = \/dev\/stdout' /etc/php5/fpm/php.ini && \
    sed -i '/;always_populate_raw_post_data/c always_populate_raw_post_data = -1' /etc/php5/fpm/php.ini && \
    sed -i '/user = /c user = docker' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/listen = /c listen = 0.0.0.0:9000' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/listen.allowed_clients/c ;listen.allowed_clients =' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/;daemonize/c daemonize = no' /etc/php5/fpm/php-fpm.conf && \
    sed -i '/;catch_workers_output/c catch_workers_output = yes' /etc/php5/fpm/php-fpm.conf && \
    # PHP CLI settings
    sed -i '/memory_limit = /c memory_limit = 512M' /etc/php5/cli/php.ini && \
    sed -i '/max_execution_time = /c max_execution_time = 600' /etc/php5/cli/php.ini && \
    sed -i '/error_log = php_errors.log/c error_log = \/dev\/stdout' /etc/php5/cli/php.ini && \
    # PHP module settings
    echo 'opcache.memory_consumption=128' >> /etc/php5/mods-available/opcache.ini

COPY config/php5/xdebug.ini /etc/php5/mods-available/xdebug.ini

# Adding NodeJS repo (for up-to-date versions)
# This is a stripped down version of the official nodejs install script (https://deb.nodesource.com/setup_4.x)
RUN curl -sSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    echo 'deb https://deb.nodesource.com/node_4.x jessie main' > /etc/apt/sources.list.d/nodesource.list && \
    echo 'deb-src https://deb.nodesource.com/node_4.x jessie main' >> /etc/apt/sources.list.d/nodesource.list

# Other language packages and dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    ruby-full \
    rlwrap \
    build-essential \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean &&\
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# bundler
RUN gem install bundler
# Home directory for bundle installs
ENV BUNDLE_PATH .bundler

RUN \
    # Composer
    curl -sSL https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    # Drupal Console
    curl -sSL http://drupalconsole.com/installer | php && \
    mv console.phar /usr/local/bin/drupal
ENV PATH /home/docker/.composer/vendor/bin:$PATH

# All further RUN commands will run as the "docker" user
USER docker

# Install nvm and a default node version
ENV NODE_VERSION 4.2.2
ENV NVM_DIR /home/docker/.nvm
RUN \
    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.29.0/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    # Install global node packages
    npm install -g npm && \
    npm install -g bower

RUN \
    # Drush 6,7 (default),8
    composer global require drush/drush:7.* && \
    mkdir /home/docker/drush6 && cd /home/docker/drush6 && composer require drush/drush:6.* && \
    mkdir /home/docker/drush8 && cd /home/docker/drush8 && composer require drush/drush:dev-master --prefer-dist && \
    echo "alias drush6='/home/docker/drush6/vendor/bin/drush'" >> /home/docker/.bashrc && \
    echo "alias drush7='/home/docker/.composer/vendor/bin/drush'" >> /home/docker/.bashrc && \
    echo "alias drush8='/home/docker/drush8/vendor/bin/drush'" >> /home/docker/.bashrc && \
    # Drush modules
    drush dl registry_rebuild && \
    # Drupal Coder (8.x) => matching version of PHP_CodeSniffer
    composer global require drupal/coder && \
    drush dl coder-8.x-2.3 --destination=/home/docker/.drush && \
    phpcs --config-set installed_paths /home/docker/.composer/vendor/drupal/coder/coder_sniffer

# Copy configs and scripts
COPY config/.ssh /home/docker/.ssh
COPY config/.drush /home/docker/.drush
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY startup.sh /opt/startup.sh

# Fix permissions after COPY
RUN sudo chown -R docker:users /home/docker

EXPOSE 9000

WORKDIR /var/www

# Default SSH key name
ENV SSH_KEY_NAME id_rsa

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD ["gosu", "root", "supervisord"]
