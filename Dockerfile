FROM debian:jessie

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
    echo 'deb-src https://packagecloud.io/github/git-lfs/debian/ jessie main' >> /etc/apt/sources.list.d/github_git-lfs.list

# Additional packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    dnsutils \
    git \
    git-lfs \
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
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
    # Create a non-root user with access to sudo and the default group set to 'users' (gid = 100)
    useradd -m -s /bin/bash -g users -G sudo -p docker docker && \
    echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install gosu and give access to the users group to use it. gosu will be used to run services as a different user.
RUN curl -sSL "https://github.com/tianon/gosu/releases/download/1.7/gosu-$(dpkg --print-architecture)" -o /usr/local/bin/gosu && \
    chown root:users /usr/local/bin/gosu && \
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

# Add Dotdeb PHP7.0 repo
RUN curl -sSL https://www.dotdeb.org/dotdeb.gpg | apt-key add - && \
	echo 'deb https://packages.dotdeb.org jessie all' > /etc/apt/sources.list.d/php7.list && \
    echo 'deb-src https://packages.dotdeb.org jessie all' >> /etc/apt/sources.list.d/php7.list

# PHP packages
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --force-yes --no-install-recommends install \
    blackfire-php \
    php-pear \
    php7.0-bcmath \
    php7.0-cli \
    php7.0-common \
    php7.0-curl \
    php7.0-fpm \
    php7.0-gd \
    php7.0-imagick \
    php7.0-intl \
    php7.0-json \
    php7.0-ldap \
    php7.0-mbstring \
    php7.0-mcrypt \
    php7.0-memcache \
    php7.0-mysql \
    php7.0-sqlite3 \
    php7.0-xdebug \
    php7.0-xml \
    php7.0-zip \
    # Cleanup
    && DEBIAN_FRONTEND=noninteractive apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## PHP settings
RUN mkdir -p /var/www/docroot && \
    # PHP-FPM settings
    ## /etc/php/7.0/fpm/php.ini
    sed -i '/memory_limit =/c memory_limit = 256M' /etc/php/7.0/fpm/php.ini && \
    sed -i '/max_execution_time =/c max_execution_time = 300' /etc/php/7.0/fpm/php.ini && \
    sed -i '/upload_max_filesize =/c upload_max_filesize = 500M' /etc/php/7.0/fpm/php.ini && \
    sed -i '/post_max_size =/c post_max_size = 500M' /etc/php/7.0/fpm/php.ini && \
    sed -i '/error_log =/c error_log = \/dev\/stdout' /etc/php/7.0/fpm/php.ini && \
    sed -i '/always_populate_raw_post_data =/c always_populate_raw_post_data = -1' /etc/php/7.0/fpm/php.ini && \
    sed -i '/sendmail_path =/c sendmail_path = /bin/true' /etc/php/7.0/fpm/php.ini && \
    sed -i '/date.timezone =/c date.timezone = UTC' /etc/php/7.0/fpm/php.ini && \
    sed -i '/display_errors =/c display_errors = On' /etc/php/7.0/fpm/php.ini && \
    sed -i '/display_startup_errors =/c display_startup_errors = On' /etc/php/7.0/fpm/php.ini && \
    ## /etc/php/7.0/fpm/pool.d/www.conf
    sed -i '/user =/c user = docker' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i '/catch_workers_output =/c catch_workers_output = yes' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i '/listen =/c listen = 0.0.0.0:9000' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i '/listen.allowed_clients/c ;listen.allowed_clients =' /etc/php/7.0/fpm/pool.d/www.conf && \
    sed -i '/clear_env =/c clear_env = no' /etc/php/7.0/fpm/pool.d/www.conf && \
    ## /etc/php/7.0/fpm/php-fpm.conf
    sed -i '/daemonize =/c daemonize = no' /etc/php/7.0/fpm/php-fpm.conf && \
    sed -i '/error_log =/c error_log = \/dev\/stdout' /etc/php/7.0/fpm/php-fpm.conf && \
    sed -i '/pid =/c pid = \/run\/php-fpm7.0.pid' /etc/php/7.0/fpm/php-fpm.conf && \
    # PHP CLI settings
    ## /etc/php/7.0/cli/php.ini
    sed -i '/memory_limit =/c memory_limit = 512M' /etc/php/7.0/cli/php.ini && \
    sed -i '/max_execution_time =/c max_execution_time = 600' /etc/php/7.0/cli/php.ini && \
    sed -i '/error_log =/c error_log = \/dev\/stdout' /etc/php/7.0/cli/php.ini && \
    sed -i '/always_populate_raw_post_data/c always_populate_raw_post_data = -1' /etc/php/7.0/cli/php.ini && \
    sed -i '/sendmail_path/c sendmail_path = /bin/true' /etc/php/7.0/cli/php.ini && \
    sed -i '/date.timezone/c date.timezone = UTC' /etc/php/7.0/cli/php.ini && \
    sed -i '/display_errors =/c display_errors = On' /etc/php/7.0/cli/php.ini && \
    sed -i '/display_startup_errors =/c display_startup_errors = On' /etc/php/7.0/cli/php.ini && \
    # PHP module settings
    echo 'opcache.memory_consumption = 128' >> /etc/php/7.0/mods-available/opcache.ini && \
    sed -i '/blackfire.agent_socket = /c blackfire.agent_socket = tcp://blackfire:8707' /etc/php/7.0/mods-available/blackfire.ini && \
    # Disable xdebug by default. We will enabled it at startup (see startup.sh)
    phpdismod xdebug && \
    # Create symlinks to project level overrides
    ln -s /var/www/.docksal/etc/php/php.ini /etc/php/7.0/fpm/conf.d/99-overrides.ini && \
    ln -s /var/www/.docksal/etc/php/php-cli.ini /etc/php/7.0/cli/conf.d/99-overrides.ini

# xdebug settings
ENV XDEBUG_ENABLED 0
COPY config/php/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini

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

ENV COMPOSER_VERSION 1.3.0
ENV DRUSH_VERSION 8.1.9
ENV DRUPAL_CONSOLE_VERSION 1.0.0-rc15
ENV MHSENDMAIL_VERSION 0.2.0
ENV WPCLI_VERSION 1.1.0
ENV MG_CODEGEN_VERSION 1.4
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
ENV NVM_VERSION 0.33.0
ENV NODE_VERSION 6.9.5
ENV NVM_DIR $HOME/.nvm
RUN \
    curl -sSL https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    # Install global node packages
    npm install -g npm && \
    npm install -g bower

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
    # Cleanup
    composer clear-cache

# Copy configs and scripts
COPY config/.ssh $HOME/.ssh
COPY config/.drush $HOME/.drush
COPY config/.zpreztorc $HOME/.zpreztorc
COPY config/.docksalrc $HOME/.docksalrc
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY startup.sh /opt/startup.sh

# Fix permissions after COPY
RUN sudo chown -R docker:users $HOME

EXPOSE 9000
EXPOSE 22

WORKDIR /var/www

# Default SSH key name
ENV SSH_KEY_NAME id_rsa
# ssh-agent proxy socket (requires docksal/ssh-agent)
ENV SSH_AUTH_SOCK /.ssh-agent/proxy-socket
# Set TERM so text editors/etc. can be used
ENV TERM xterm

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD ["gosu", "root", "supervisord"]
