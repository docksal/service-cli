FROM php:7.0-fpm

# Prevent services autoload (http://jpetazzo.github.io/2013/10/06/policy-rc-d-do-not-start-services-automatically/)
RUN echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Basic packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    apt-transport-https \
    ca-certificates \
    curl \
    locales \
    wget \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Set timezone and locale
RUN dpkg-reconfigure locales && \
    locale-gen C.UTF-8 && \
    /usr/sbin/update-locale LANG=C.UTF-8
ENV LC_ALL C.UTF-8

# Enabling additional repos
RUN sed -i 's/main/main contrib non-free/' /etc/apt/sources.list && \
    # Include blackfire.io repo
    curl -sSL https://packagecloud.io/gpg.key | apt-key add - && \
    echo "deb https://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list && \
    # Include git-lfs repo
    curl -sSL https://packagecloud.io/github/git-lfs/gpgkey | apt-key add - && \
    echo 'deb https://packagecloud.io/github/git-lfs/debian/ jessie main' > /etc/apt/sources.list.d/github_git-lfs.list && \
    echo 'deb-src https://packagecloud.io/github/git-lfs/debian/ jessie main' >> /etc/apt/sources.list.d/github_git-lfs.list && \
	# Including yarn repo
	curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Additional packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    dnsutils \
    git \
    git-lfs \
    ghostscript \
    imagemagick \
    less \
    mc \
    mysql-client \
    nano \
    openssh-client \
    openssh-server \
    procps \
    pv \
    rsync \
    sudo \
    supervisor \
    unzip \
    zip \
    zsh \
    yarn \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
    # Create a regular user/group "docker" (uid = 1000, gid = 1000 ) with access to sudo
    groupadd docker -g 1000 && \
    useradd -m -s /bin/bash -u 1000 -g 1000 -G sudo -p docker docker && \
    echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install gosu and give access to the docker user primary group to use it.
# gosu is used instead of sudo to start the main container process (pid 1) in a docker friendly way.
# https://github.com/tianon/gosu
RUN curl -sSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" -o /usr/local/bin/gosu && \
    chown root:"$(id -gn docker)" /usr/local/bin/gosu && \
    chmod +sx /usr/local/bin/gosu

# Configure sshd (for use PHPStorm's remote interpreters and tools integrations)
# http://docs.docker.com/examples/running_ssh_service/
RUN mkdir /var/run/sshd & \
    echo 'docker:docker' | chpasswd && \
    sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    # SSH login fix. Otherwise user is kicked off after login
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd && \
    echo "export VISIBLE=now" >> /etc/profile
ENV NOTVISIBLE "in users profile"

# Needed to install PHP extentions
RUN buildDeps="zlib1g-dev \
    libmcrypt-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng12-dev \
    libmagickwand-dev \
    libmagickcore-dev \
    libmemcached-dev \
    libldap2-dev \
    libssh2-1-dev \
    libmhash-dev \
    zlib1g-dev \
    libicu-dev \
    g++ \
    libxslt1-dev \
    libgpgme11-dev" \
    && DEBIAN_FRONTEND=noninteractive apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    $buildDeps \
    blackfire-php \
    zlib1g \
    libmcrypt4 \
    libfreetype6 \
    libjpeg62-turbo \
    libpng12-0 \
    libmagickwand-6.q16-2 \
    libmagickcore-6.q16-2 \
    libmemcached11 \
    libmemcachedutil2 \
    libldap-2.4-2 \
    libssh2-1 \
    libmhash2 \
    zlib1g \
    libicu52 \
    libxslt1.1 \
    libgpgme11 \
    # SSH2 must be installed from source
    && git clone https://github.com/php/pecl-networking-ssh2.git /usr/src/php/ext/ssh2 \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    # Removed memcache for PHP 7.x. See https://groups.drupal.org/node/513801 for reasoning
    && docker-php-ext-configure hash --with-mhash \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
    && docker-php-ext-install -j$(nproc) \
       bcmath \
       bz2 \
       calendar\
       dba \
       exif \
       gd \
       gettext \
       intl \
       ldap \
       mcrypt \
       opcache \
       pcntl \
       pdo_mysql \
       shmop \
       soap \
       sockets \
       ssh2 \
       sysvmsg \
       sysvsem \
       sysvshm \
       wddx \
       xsl \
       zip \
    && pecl update-channels \
    && pecl install memcached \
    && pecl install xdebug \
    && pecl install gnupg \
    && pecl install imagick \
    && pecl install redis \
    && docker-php-ext-enable memcached gnupg imagick redis \
    # Cleanup
    && docker-php-source delete \
    && rm -rf /tmp/pear ~/.pearrc \
    && DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps \
    && DEBIAN_FRONTEND=noninteractive apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
    
## PHP settings
## /usr/local/etc/php/php.ini
COPY config/php/php-cli.ini /usr/local/etc/php/php.ini
RUN \
    # PHP-FPM settings
    ## /usr/local/etc/php-fpm.d/www.conf
    sed -i '/memory_limit/c php_admin_value[memory_limit] = 256M' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i '/sendmail_path/c php_admin_value[sendmail_path] = /bin/true' /usr/local/etc/php-fpm.d/www.conf && \
    echo 'php_admin_value[max_execution_time] = 300' >>/usr/local/etc/php-fpm.d/www.conf && \
    echo 'php_admin_value[upload_max_filesize] = 500M' >>/usr/local/etc/php-fpm.d/www.conf && \
    echo 'php_admin_value[post_max_size] = 500M' >>/usr/local/etc/php-fpm.d/www.conf && \
    echo 'php_admin_value[date.timezone] = UTC' >>/usr/local/etc/php-fpm.d/www.conf && \
    echo 'php_admin_value[display_errors] = On' >>/usr/local/etc/php-fpm.d/www.conf && \
    echo 'php_admin_value[display_startup_errors] = On' >>/usr/local/etc/php-fpm.d/www.conf && \
    sed -i '/user =/c user = docker' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i '/catch_workers_output =/c catch_workers_output = yes' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i '/listen =/c listen = 0.0.0.0:9000' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i '/listen.allowed_clients/c ;listen.allowed_clients =' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i '/clear_env =/c clear_env = no' /usr/local/etc/php-fpm.d/www.conf && \
    sed -i '/pid =/c pid = \/run\/php-fpm.pid' /usr/local/etc/php-fpm.conf && \
    # PHP module settings
    echo 'opcache.memory_consumption = 128' >> /usr/local/etc/php/conf.d/docker-php-ext-opcache.ini && \
    sed -i '/blackfire.agent_socket = /c blackfire.agent_socket = tcp://blackfire:8707' /usr/local/etc/php/conf.d/zz-blackfire.ini && \
    # remove xdebug ini file, get linked in startup.sh
    rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini && \
    # Create symlinks to project level overrides (if the source files are missing, nothing will break)
    ln -s /var/www/.docksal/etc/php/php-fpm.conf /usr/local/etc/php-fpm.d/php-fpm.conf && \
    ln -s /var/www/.docksal/etc/php/php-cli.ini /usr/local/etc/php/conf.d/zz-overrides.ini

# xdebug settings
ENV XDEBUG_ENABLED 0
COPY config/php/xdebug.ini /opt/docker-php-ext-xdebug.ini

# Other language packages and dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get clean && apt-get update && \
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

ENV COMPOSER_VERSION=1.5.2 \
	DRUSH_VERSION=8.1.13 \
	DRUPAL_CONSOLE_VERSION=1.0.2 \
	MHSENDMAIL_VERSION=0.2.0 \
	WPCLI_VERSION=1.3.0 \
	MG_CODEGEN_VERSION=1.6.4 \
	BLACKFIRE_VERSION=1.14.1
RUN \
    # Composer
    curl -sSL "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" -o /usr/local/bin/composer && \
    # Drush 8 (default)
    curl -sSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/local/bin/drush && \
    # Drupal Console
    curl -sSL "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_VERSION}/drupal.phar" -o /usr/local/bin/drupal && \
    # mhsendmail for MailHog integration
    curl -sSL "https://github.com/mailhog/mhsendmail/releases/download/v${MHSENDMAIL_VERSION}/mhsendmail_linux_amd64" -o /usr/local/bin/mhsendmail && \
    # Install wp-cli
    curl -sSL "https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar" -o /usr/local/bin/wp && \
    # Install magento code generator
    curl -sSL "https://github.com/staempfli/magento2-code-generator/releases/download/${MG_CODEGEN_VERSION}/mg2-codegen.phar" -o /usr/local/bin/mg2-codegen && \
    # Install blackfire cli
    curl -L https://packages.blackfire.io/binaries/blackfire-agent/${BLACKFIRE_VERSION}/blackfire-cli-linux_static_amd64 -o /usr/local/bin/blackfire && \
    # Make all binaries executable
    chmod +x /usr/local/bin/*

# All further RUN commands will run as the "docker" user
USER docker
ENV HOME /home/docker

# Install Prezto zsh shell
RUN git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto" && \
    ln -s $HOME/.zprezto/runcoms/zlogin $HOME/.zlogin && \
    ln -s $HOME/.zprezto/runcoms/zlogout $HOME/.zlogout && \
    ln -s $HOME/.zprezto/runcoms/zpreztorc $HOME/.zpreztorc && \
    ln -s $HOME/.zprezto/runcoms/zprofile $HOME/.zprofile && \
    ln -s $HOME/.zprezto/runcoms/zshenv $HOME/.zshenv && \
    ln -s $HOME/.zprezto/runcoms/zshrc $HOME/.zshrc

# Install nvm and a default node version
ENV NVM_VERSION=0.33.4 \
	NODE_VERSION=6.11.3 \
	NVM_DIR=$HOME/.nvm
RUN \
    curl -sSL https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    # Install global node packages
    npm install -g npm && \
	# Cleanup
	nvm clear-cache && npm cache clear --force && \
	# Fix npm complaining about permissions and not being able to update
	sudo rm -rf $HOME/.config

ENV PATH $PATH:$HOME/.composer/vendor/bin
RUN \
    # Add composer bin directory to PATH
    echo "\n"'PATH="$PATH:$HOME/.composer/vendor/bin"' >> $HOME/.profile && \
    # Legacy Drush versions (6 and 7)
    mkdir $HOME/drush6 && cd $HOME/drush6 && composer require drush/drush:6.* && \
    mkdir $HOME/drush7 && cd $HOME/drush7 && composer require drush/drush:7.* && \
    echo "alias drush6='$HOME/drush6/vendor/bin/drush'" >> $HOME/.bash_aliases && \
    echo "alias drush7='$HOME/drush7/vendor/bin/drush'" >> $HOME/.bash_aliases && \
    echo "alias drush8='/usr/local/bin/drush'" >> $HOME/.bash_aliases && \
    # Drush modules
    drush dl registry_rebuild --default-major=7 --destination=$HOME/.drush && \
    drush cc drush && \
    # Drupal Coder w/ a matching version of PHP_CodeSniffer
    composer global require drupal/coder && \
    phpcs --config-set installed_paths $HOME/.composer/vendor/drupal/coder/coder_sniffer && \
    # Composer parallel install plugin
    composer global require hirak/prestissimo && \
    # Cleanup
    composer clear-cache

# Copy configs and scripts
# Docker does not honor the USER directive when doing COPY/ADD.
# To not bloat the image size permissions on the home folder are reset during image startup (in startup.sh)
COPY config/.ssh $HOME/.ssh
COPY config/.drush $HOME/.drush
COPY config/.zpreztorc $HOME/.zpreztorc
COPY config/.docksalrc $HOME/.docksalrc
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY startup.sh /opt/startup.sh
COPY healthcheck.sh /opt/healthcheck.sh
COPY index.php /var/www/index.php

ENV \
	# ssh-agent proxy socket (requires docksal/ssh-agent)
	SSH_AUTH_SOCK=/.ssh-agent/proxy-socket \
	# Set TERM so text editors/etc. can be used
	TERM=xterm \
	# Allow PROJECT_ROOT to be universally used in fin custom commands (inside and outside cli)
	PROJECT_ROOT=/var/www \
	# Default values for HOST_UID and HOST_GUI to match the default Ubuntu user. These are used in startup.sh
	HOST_UID=1000 \
	HOST_GID=1000

USER root

EXPOSE 9000
EXPOSE 22

WORKDIR /var/www

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD ["supervisord"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=12 CMD ["/opt/healthcheck.sh"]
