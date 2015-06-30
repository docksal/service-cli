#FROM ubuntu:12.04
FROM debian:wheezy
#FROM debian:jessie

MAINTAINER Leonid Makarov <leonid.makarov@blinkreaction.com>

# Prevent services autoload (http://jpetazzo.github.io/2013/10/06/policy-rc-d-do-not-start-services-automatically/)
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Enabling additional repos
RUN sed -i 's/main/main contrib non-free/' /etc/apt/sources.list

# Add Dotdeb PHP5.6 repo
RUN echo 'deb http://packages.dotdeb.org wheezy-php56 all' >> /etc/apt/sources.list && \
    echo 'deb-src http://packages.dotdeb.org wheezy-php56 all' >> /etc/apt/sources.list && \
    # Dotdeb repo key
    #wget http://www.dotdeb.org/dotdeb.gpg && apt-key add dotdeb.gpg
    gpg --keyserver keys.gnupg.net --recv-key 89DF5277 && \
    gpg -a --export 89DF5277 | apt-key add -

# Basic packages
RUN \
    # Update system
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    #DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    # Install packages
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y install \
    pv curl wget zip git mysql-client locales supervisor ca-certificates \
    --no-install-recommends && \
    # Cleanup
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# PHP packages
RUN \
    # Update system
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    #DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    # Install packages
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y install \
    pv curl wget zip git mysql-client locales supervisor \
    php5-fpm php5-mysql php5-imagick imagemagick \
    php5-mcrypt php5-curl php5-gd php5-sqlite php5-common \
    php-pear php5-json php5-memcache php5-xdebug php5-intl \
    --no-install-recommends && \
    # Cleanup
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Other language packages and dependencies
RUN \
    # Update system
    DEBIAN_FRONTEND=noninteractive apt-get update && \
    #DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y && \
    # Install packages
    DEBIAN_FRONTEND=noninteractive \
    apt-get -y install \
    ruby-full rlwrap \
    --no-install-recommends && \
    # Cleanup
    DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set timezone and locale.
RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8
ENV LC_ALL C.UTF-8

# Bundler
RUN gem install bundler

# Node JS 0.12.0
RUN curl https://deb.nodesource.com/node012/pool/main/n/nodejs/nodejs_0.12.0-1nodesource1~wheezy1_amd64.deb > node.deb \
    && dpkg -i node.deb \
    && rm node.deb

# Grunt, Bower
RUN npm install -g grunt-cli bower

# Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Drush and Drupal Console
RUN composer global require drush/drush:7.* && \
    curl -LSs http://drupalconsole.com/installer | php && \
    mv console.phar /usr/local/bin/drupal

RUN \
    # PHP settings changes
    sed -i 's/memory_limit = .*/memory_limit = 512M/' /etc/php5/cli/php.ini && \
    sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php5/cli/php.ini && \
    sed -i 's/upload_max_filesize = .*/upload_max_filesize = 500M/' /etc/php5/fpm/php.ini && \
    sed -i 's/post_max_size = .*/post_max_size = 500M/' /etc/php5/fpm/php.ini && \
    sed -i "/error_log = php_errors.log/c\error_log = \/dev\/stdout/" /etc/php5/fpm/php.ini && \
    # PHP FPM config changes
    sed -i '/listen = /c\listen = 0.0.0.0:9000' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/listen.allowed_clients/c\;listen.allowed_clients =' /etc/php5/fpm/pool.d/www.conf && \
    sed -i "/;daemonize = yes/c\daemonize = no" /etc/php5/fpm/php-fpm.conf && \
    sed -i '/;catch_workers_output/c\catch_workers_output = yes' /etc/php5/fpm/php-fpm.conf

WORKDIR /var/www

# Add Composer bin directory to PATH
ENV PATH /root/.composer/vendor/bin:$PATH

# Home directory for bundle installs
ENV BUNDLE_PATH .bundler

# SSH settigns
COPY config/.ssh /root/.ssh
# Drush settings
COPY config/.drush /root/.drush

# Startup script
COPY ./startup.sh /opt/startup.sh
RUN chmod +x /opt/startup.sh

# Startup script
COPY ./startup-local.sh /opt/startup-local.sh
RUN chmod +x /opt/startup-local.sh

# supervisord config
COPY ./config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 9000

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD /usr/bin/supervisord -n
