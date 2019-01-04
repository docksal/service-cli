# Build mhsendmail
FROM golang:1.8.3 as mhbuild
ENV MHSENDMAIL_VERSION=0.2.0
RUN set -xe; \
  go get -d github.com/mailhog/mhsendmail; \
  cd /go/src/github.com/mailhog/mhsendmail; \
  git checkout tags/v${MHSENDMAIL_VERSION}; \
  go get github.com/mailhog/mhsendmail

# Build the image
FROM php:7.2-fpm

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# Prevent services autoload (http://jpetazzo.github.io/2013/10/06/policy-rc-d-do-not-start-services-automatically/)
RUN set -xe; \
	echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Install basic packages
RUN set -xe; \
	apt-get update >/dev/null; \
	apt-get -y --no-install-recommends install >/dev/null \
		apt-transport-https \
		# ca-certificates and curl come from upstream
		#ca-certificates \
		#curl \
		gnupg \
		locales \
		wget \
	;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

# Set en_US.UTF-8 as the default locale
RUN set -xe; \
	localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LC_ALL en_US.utf8

# Enable additional repos
RUN set -xe; \
	sed -i 's/main/main contrib non-free/' /etc/apt/sources.list; \
	# blackfire.io repo
	curl -fsSL https://packagecloud.io/gpg.key | apt-key add -; \
	echo "deb https://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list; \
	# git-lfs repo
	curl -fsSL https://packagecloud.io/github/git-lfs/gpgkey | apt-key add -; \
	echo 'deb https://packagecloud.io/github/git-lfs/debian stretch main' | tee /etc/apt/sources.list.d/github_git-lfs.list; \
	echo 'deb-src https://packagecloud.io/github/git-lfs/debian stretch main' | tee -a /etc/apt/sources.list.d/github_git-lfs.list; \
	# MSQSQL repo - msodbcsql17, pecl/sqlsrv and pecl/pdo_sqlsrv (PHP 7.0+ only)
	curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -; \
	echo 'deb https://packages.microsoft.com/debian/9/prod stretch main' | tee /etc/apt/sources.list.d/mssql.list;

# Additional packages
RUN set -xe; \
	# Create man direcotries, otherwise some packages may not install (e.g. postgresql-client)
	# This should be a temporary workaround until fixed upstream: https://github.com/debuerreotype/debuerreotype/issues/10
	mkdir -p /usr/share/man/man1 /usr/share/man/man7; \
	apt-get update >/dev/null; \
	apt-get -y --no-install-recommends install >/dev/null \
		cron \
		dnsutils \
		git \
		git-lfs \
		ghostscript \
		# html2text binary - used for self-testing (php-fpm)
		html2text \
		imagemagick \
		iputils-ping \
		less \
		# cgi-fcgi binary - used for self-testing (php-fpm)
		libfcgi-bin \
		mc \
		mysql-client \
		nano \
		openssh-client \
		openssh-server \
		postgresql-client \
		procps \
		pv \
		rsync \
		sudo \
		supervisor \
		unzip \
		zip \
	;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

RUN set -xe; \
	# Create a regular user/group "docker" (uid = 1000, gid = 1000 )
	groupadd docker -g 1000; \
	useradd -m -s /bin/bash -u 1000 -g 1000 -p docker docker; \
	# Give the docker user sudo access
	usermod -a -G sudo docker; \
	echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ENV GOSU_VERSION=1.10 \
	GOMPLATE_VERSION=3.0.0
RUN set -xe; \
	# Install gosu and give access to the docker user primary group to use it.
	# gosu is used instead of sudo to start the main container process (pid 1) in a docker friendly way.
	# https://github.com/tianon/gosu
	curl -fsSL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$(dpkg --print-architecture)" -o /usr/local/bin/gosu; \
	chown root:"$(id -gn docker)" /usr/local/bin/gosu; \
	chmod +sx /usr/local/bin/gosu; \
	# gomplate (to process configuration templates in startup.sh)
	curl -fsSL https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-amd64-slim -o /usr/local/bin/gomplate; \
	chmod +x /usr/local/bin/gomplate

# Configure sshd (for use PHPStorm's remote interpreters and tools integrations)
# http://docs.docker.com/examples/running_ssh_service/
RUN set -xe; \
	mkdir /var/run/sshd; \
	echo 'docker:docker' | chpasswd; \
	sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config; \
	# SSH login fix. Otherwise user is kicked off after login
	sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd; \
	echo "export VISIBLE=now" >> /etc/profile
ENV NOTVISIBLE "in users profile"

# PHP
RUN set -xe; \
	# Note: essential build tools (g++, gcc, make, etc) are included upstream as persistent packages.
	# See https://github.com/docker-library/php/blob/4af0a8734a48ab84ee96de513aabc45418b63dc5/7.2/stretch/fpm/Dockerfile#L18-L37
	buildDeps=" \
		libc-client2007e-dev \
		libfreetype6-dev \
		libgpgme11-dev \
		libicu-dev \
		libjpeg62-turbo-dev \
		libkrb5-dev \
		libldap2-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmcrypt-dev \
		libmemcached-dev \
		libmhash-dev \
		libpng-dev \
		libpq-dev \
		libssh2-1-dev \
		libxslt1-dev \
		unixodbc-dev \
		zlib1g-dev \
	"; \
	apt-get update >/dev/null; \
	# Necessary for msodbcsql17 (MSSQL)
	ACCEPT_EULA=Y \
	apt-get -y --no-install-recommends install >/dev/null \
		$buildDeps \
		blackfire-php \
		libc-client2007e \
		libfreetype6 \
		libgpgme11 \
		libicu57 \
		libjpeg62-turbo \
		libldap-2.4-2 \
		libmagickcore-6.q16-3 \
		libmagickwand-6.q16-3 \
		libmcrypt4 \
		libmemcached11 \
		libmemcachedutil2 \
		libmhash2 \
		libpng16-16 \
		libpq5 \
		libssh2-1 \
		libxslt1.1 \
		msodbcsql17 \
		zlib1g \
	;\
	# SSH2 must be installed from source
	git clone https://github.com/php/pecl-networking-ssh2.git /usr/src/php/ext/ssh2 && rm -rf /usr/src/php/ext/ssh2/.git; \
	# XDEBUG must be installed from source
	git clone https://github.com/xdebug/xdebug.git /usr/src/php/ext/xdebug && rm -rf /usr/src/php/ext/xdebug/.git; \
	\
	docker-php-ext-configure >/dev/null gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/; \
	docker-php-ext-configure >/dev/null imap --with-kerberos --with-imap-ssl; \
	docker-php-ext-configure >/dev/null ldap --with-libdir=lib/x86_64-linux-gnu/; \
	docker-php-ext-configure >/dev/null pgsql --with-pgsql=/usr/local/pgsql/; \
	\
	docker-php-ext-install >/dev/null -j$(nproc) \
		bcmath \
		bz2 \
		calendar\
		exif \
		gd \
		gettext \
		imap \
		intl \
		ldap \
		# mcrypt is removed from 7.2. See Deprecated features
		mysqli \
		opcache \
		pcntl \
		pdo_mysql \
		pdo_pgsql \
		pgsql \
		soap \
		sockets \
		ssh2 \
		xdebug \
		xsl \
		zip \
	;\
	pecl update-channels; \
	pecl install >/dev/null </dev/null \
		apcu \
		gnupg \
		imagick \
		# Use memcached (not memcache) for PHP 7.x
		memcached \
		pdo_sqlsrv \
		redis \
		sqlsrv \
	;\
	docker-php-ext-enable \
		apcu \
		gnupg \
		imagick \
		memcached \
		pdo_sqlsrv \
		redis \
		sqlsrv \
	;\
	# Disable xdebug by default
	rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
	# Cleanup
	docker-php-source delete; \
	rm -rf /tmp/pear ~/.pearrc; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	apt-get clean; rm -rf /var/lib/apt/lists/*

# PHP tools (installed globally)
ENV COMPOSER_VERSION=1.7.2 \
	DRUSH_VERSION=8.1.17 \
	DRUSH_LAUNCHER_VERSION=0.6.0 \
	DRUPAL_CONSOLE_LAUNCHER_VERSION=1.8.0 \
	WPCLI_VERSION=2.0.1 \
	BLACKFIRE_VERSION=1.20.0 \
	PLATFORMSH_CLI_VERSION=3.35.1
RUN set -xe; \
	# Composer
	curl -fsSL "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" -o /usr/local/bin/composer; \
	# Drush 8 (global fallback)
	curl -fsSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/local/bin/drush8; \
	# Drush Launcher
	curl -fsSL "https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar" -o /usr/local/bin/drush; \
	# Drupal Console Launcher
	curl -fsSL "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_LAUNCHER_VERSION}/drupal.phar" -o /usr/local/bin/drupal; \
	# Wordpress CLI
	curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar" -o /usr/local/bin/wp; \
	# Blackfire CLI
	curl -fsSL "https://packages.blackfire.io/binaries/blackfire-agent/${BLACKFIRE_VERSION}/blackfire-cli-linux_static_amd64" -o /usr/local/bin/blackfire; \
	# Platform.sh CLI
	curl -fsSL "https://github.com/platformsh/platformsh-cli/releases/download/v${PLATFORMSH_CLI_VERSION}/platform.phar" -o /usr/local/bin/platform; \
	# Make all downloaded binaries executable in one shot
	(cd /usr/local/bin && chmod +x composer drush8 drush drupal wp blackfire platform);

# All further RUN commands will run as the "docker" user
USER docker
SHELL ["/bin/bash", "-c"]

# PHP tools (installed as user)
ENV MG_CODEGEN_VERSION=1.10.2 \
	TERMINUS_VERSION=1.9.0 \
	DRUSH_BACKDROP_VERSION=0.0.6
# Don't use -x here, as the output may be excessive
RUN set -e; \
	\
	# Set drush8 as a global fallback for Drush Launcher
	echo -e "\n""export DRUSH_LAUNCHER_FALLBACK=/usr/local/bin/drush8" >> $HOME/.profile; \
	# Composer based dependencies
	# Add composer bin directory to PATH
	echo -e "\n"'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> $HOME/.profile; \
	# Reload updated PATH from profile to make composer/drush/etc. visible below
	. $HOME/.profile; \
	# Install cgr to use it in-place of `composer global require`
	composer global require consolidation/cgr >/dev/null; \
	# Composer parallel install plugin
	composer global require hirak/prestissimo >/dev/null; \
	# Drupal Coder & WP Coding Standards w/ a matching version of PHP_CodeSniffer
	cgr drupal/coder wp-coding-standards/wpcs >/dev/null; \
	phpcs --config-set installed_paths "$HOME/.composer/global/drupal/coder/vendor/drupal/coder/coder_sniffer/,$HOME/.composer/global/wp-coding-standards/wpcs/vendor/wp-coding-standards/wpcs/"; \
	# Magento2 Code Generator
	cgr staempfli/magento2-code-generator:${MG_CODEGEN_VERSION} >/dev/null; \
	# Terminus
	cgr pantheon-systems/terminus:${TERMINUS_VERSION} >/dev/null; \
	# Cleanup
	composer clear-cache; \
	\
	# Drush modules
	drush dl registry_rebuild --default-major=7 --destination=$HOME/.drush >/dev/null; \
	mkdir $HOME/.drush/backdrop && curl -fsSL "https://github.com/backdrop-contrib/drush/archive/${DRUSH_BACKDROP_VERSION}.tar.gz" | tar xz -C $HOME/.drush/backdrop --strip-components 1; \
	drush cc drush

# Node.js (installed as user)
ENV \
	NVM_VERSION=0.33.11 \
	NODE_VERSION=10.15.0 \
	YARN_VERSION=1.13.0
# Don't use -x here, as the output may be excessive
RUN set -e; \
	# NVM and a defaut Node.js version
	export PROFILE="$HOME/.profile"; \
	curl -fsSL https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash >/dev/null; \
	# Reload profile to load nvm (needed by Yarn installation below)
	. $HOME/.profile; \
	# Yarn
	export YARN_PROFILE="$HOME/.profile"; \
	curl -fsSL https://yarnpkg.com/install.sh | bash -s -- --version ${YARN_VERSION} >/dev/null

# Ruby (installed as user)
ENV \
	RVM_VERSION_INSTALL=1.29.6 \
	RUBY_VERSION_INSTALL=2.6.0
# Don't use -x here, as the output may be excessive
RUN set -e; \
	# Public GPG servers are not realiable, so downloading keys from rvm.io instead.
	#gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
	curl -sSL https://rvm.io/mpapis.asc | gpg --batch --import -; \
	curl -sSL https://rvm.io/pkuczynski.asc | gpg --batch --import -; \
	\
	echo 'rvm_autoupdate_flag=0' >> $HOME/.rvmrc; \
	echo 'rvm_silence_path_mismatch_check_flag=1' >> $HOME/.rvmrc; \
	curl -fsSL https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION_INSTALL}/binscripts/rvm-installer | bash -s -- --ignore-dotfiles --version ${RVM_VERSION_INSTALL}; \
	{ \
		echo ''; \
		echo 'export PATH="$PATH:$HOME/.rvm/bin"'; \
		echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"'; \
	} >> $HOME/.profile; \
	# Reload $HOME/.profile to apply settings for the current shell
	. $HOME/.profile; \
	\
	# rvm.io does not currently have ruby binaries for Debian 9, so Ruby is compiled from source, which requires a bunch
	# of extra dependencies installed (rvm installs these automatically), which bloat this image:
	# rvm/ruby required packages: gawk, automake, bison, libffi-dev, libgdbm-dev, libncurses5-dev, libsqlite3-dev, libtool, libyaml-dev, sqlite3, zlib1g-dev, libgmp-dev, libreadline-dev, libssl-dev
	rvm install ruby-${RUBY_VERSION_INSTALL}; \
	rvm use ruby-${RUBY_VERSION_INSTALL} --default; \
	\
	gem install bundler; \
	# Have bundler install gems locally (./.bundle) by default
	echo -e "\n"'export BUNDLE_PATH=.bundle' >> $HOME/.profile; \
	\
	rvm cleanup all; \
	rvm gemset globalcache enable

# Python (installed as user)
ENV \
	PYENV_VERSION_INSTALL=1.2.7
#	PYTHON_VERSION_INSTALL=3.7.0
RUN set -xe; \
	git clone --depth 1 -b v${PYENV_VERSION_INSTALL} https://github.com/pyenv/pyenv.git $HOME/.pyenv; \
	rm -rf $HOME/.pyenv/.git; \
	{ \
		echo ''; \
		echo 'export PYENV_ROOT="$HOME/.pyenv"'; \
		echo 'export PATH="$PYENV_ROOT/bin:$PATH"'; \
		echo 'eval "$(pyenv init -)"'; \
	} >> $HOME/.profile
# Disabled for now - uses too much space (~200MB).
# The upsteam Debian 9 image ships with Python 2.7 out of the box, so we'll stick with that by default.
#	# Reload $HOME/.profile to apply settings for the current shell
#	. $HOME/.profile; \
#	pyenv install ${PYTHON_VERSION_INSTALL}; \
#	pyenv global ${PYTHON_VERSION_INSTALL}

USER root
SHELL ["/bin/sh", "-c"]

# Copy mhsendmail binary from stage 1
COPY --from=mhbuild /go/bin/mhsendmail /usr/local/bin/mhsendmail
# Copy configs and scripts
COPY --chown=docker:docker config/.drush /home/docker/.drush
COPY --chown=docker:docker config/.terminus /home/docker/.terminus
COPY --chown=docker:docker config/.ssh /home/docker/.ssh
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY startup.sh /opt/startup.sh
COPY healthcheck.sh /opt/healthcheck.sh
# PHP default settings, global overrides and fpm overrides
ADD https://raw.githubusercontent.com/php/php-src/PHP-${PHP_VERSION}/php.ini-development /usr/local/etc/php/php.ini
COPY config/php/zz-php.ini /usr/local/etc/php/conf.d/zz-php.ini
COPY config/php/xdebug.ini /opt/docker-php-ext-xdebug.ini
COPY config/php/zz-php-fpm.conf /usr/local/etc/php-fpm.d/zz-php-fpm.conf
# Create symlinks to project level overrides (if the source files are missing, nothing will break)
RUN set -xe; \
	ln -s /var/www/.docksal/etc/php/php.ini /usr/local/etc/php/conf.d/zzz-php.ini; \
	ln -s /var/www/.docksal/etc/php/php-fpm.conf /usr/local/etc/php-fpm.d/zzz-php-fpm.conf

ENV \
	# ssh-agent proxy socket (requires docksal/ssh-agent)
	SSH_AUTH_SOCK=/.ssh-agent/proxy-socket \
	# Set TERM so text editors/etc. can be used
	TERM=xterm \
	# Allow PROJECT_ROOT to be universally used in fin custom commands (inside and outside cli)
	PROJECT_ROOT=/var/www \
	# Default values for HOST_UID and HOST_GUI to match the default Ubuntu user. These are used in startup.sh
	HOST_UID=1000 \
	HOST_GID=1000 \
	# xdebug disabled by default
	XDEBUG_ENABLED=0

EXPOSE 9000
EXPOSE 22
EXPOSE 3000

WORKDIR /var/www

# Starter script
ENTRYPOINT ["/opt/startup.sh"]

# By default, launch supervisord to keep the container running.
CMD ["supervisord"]

# Health check script
HEALTHCHECK --interval=5s --timeout=1s --retries=12 CMD ["/opt/healthcheck.sh"]
