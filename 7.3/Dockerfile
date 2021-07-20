FROM php:7.3-fpm-buster as cli

ARG TARGETARCH
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
	curl -fsSL https://packages.blackfire.io/gpg.key | apt-key add -; \
	echo "deb https://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list; \
	# git-lfs repo
	curl -fsSL https://packagecloud.io/github/git-lfs/gpgkey | apt-key add -; \
	echo 'deb https://packagecloud.io/github/git-lfs/debian buster main' | tee /etc/apt/sources.list.d/github_git-lfs.list;

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
		msmtp \
		# Debian 10 ships with MariaDB instead of MySQL
		mariadb-client \
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
		webp \
		zip \
	;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

RUN set -xe; \
	# Create a regular user/group "docker" (uid = 1000, gid = 1000 )
	useradd -m -s /bin/bash -u 1000 -U -p docker docker; \
	# Give the docker user sudo access
	usermod -a -G sudo docker; \
	echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

ENV GOSU_VERSION=1.12 \
	GOMPLATE_VERSION=3.9.0
RUN set -xe; \
	# Install gosu and give access to the docker user primary group to use it.
	# gosu is used instead of sudo to start the main container process (pid 1) in a docker friendly way.
	# https://github.com/tianon/gosu
	curl -fsSL https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${TARGETARCH} -o /usr/local/bin/gosu; \
	chown root:$(id -gn docker) /usr/local/bin/gosu; \
	chmod +sx /usr/local/bin/gosu; \
	# gomplate (to process configuration templates in startup.sh)
	curl -fsSL https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-${TARGETARCH} -o /usr/local/bin/gomplate; \
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
	# See https://github.com/docker-library/php/blob/406fcd31e62d633f62ac0d7bc5fc29aa1b3929fc/7.2/buster/fpm/Dockerfile#L18-L40
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
		libmemcached-dev \
		libmhash-dev \
		libpng-dev \
		libpq-dev \
		libwebp-dev \
		libssh2-1-dev \
		libxpm-dev \
		libxslt1-dev \
		libzip-dev \
		unixodbc-dev \
	"; \
	apt-get update >/dev/null; \
	apt-get -y --no-install-recommends install >/dev/null \
		$buildDeps \
		blackfire-php \
		libc-client2007e \
		libfreetype6 \
		libgpgme11 \
		libicu63 \
		libjpeg62-turbo \
		libldap-2.4-2 \
		libmagickcore-6.q16-*-extra \
		libmagickwand-6.q16-6 \
		libmemcached11 \
		libmemcachedutil2 \
		libmhash2 \
		libpng16-16 \
		libpq5 \
		libssh2-1 \
		libxpm4 \
		libxslt1.1 \
		libzip4 \
	;\
	docker-php-ext-configure >/dev/null gd \
		--with-freetype-dir=/usr/include/ \
		--with-jpeg-dir=/usr/include/ \
		--with-webp-dir=/usr/include/ \
		--with-png-dir=/usr/include/ \
		--with-xpm-dir=/usr/include/; \
	docker-php-ext-configure >/dev/null imap --with-kerberos --with-imap-ssl; \
	# Using $(uname -m) (returns x86_64 / aarch64) vs ${TARGETARCH} (returns amd64 / arm64)
	docker-php-ext-configure >/dev/null ldap --with-libdir=lib/$(uname -m)-linux-gnu/; \
	docker-php-ext-configure >/dev/null pgsql --with-pgsql=/usr/local/pgsql/; \
	docker-php-ext-configure >/dev/null zip --with-libzip; \
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
		mysqli \
		opcache \
		pcntl \
		pdo_mysql \
		pdo_pgsql \
		pgsql \
		soap \
		sockets \
		xsl \
		zip \
		sysvsem \
	;\
	pecl update-channels; \
	pecl install >/dev/null </dev/null \
		apcu \
		gnupg \
		imagick \
		# Use memcached (not memcache) for PHP 7.x
		memcached \
		redis \
		ssh2-beta \
		xdebug \
		xhprof \
	;\
	docker-php-ext-enable \
		apcu \
		gnupg \
		imagick \
		memcached \
		redis \
		ssh2 \
	;\
	# Cleanup
	docker-php-source delete; \
	rm -rf /tmp/pear ~/.pearrc; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	apt-get clean; rm -rf /var/lib/apt/lists/*

# Packages not available for arm64
RUN set -xe; \
	if [ "${TARGETARCH}" = "amd64" ]; then \
		# MSQSQL repo - msodbcsql17, pecl/sqlsrv and pecl/pdo_sqlsrv (PHP 7.0+ only)
		curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | apt-key add -; \
		echo 'deb https://packages.microsoft.com/debian/10/prod buster main' | tee /etc/apt/sources.list.d/mssql.list; \
		\
		buildDeps=" \
			unixodbc-dev \
		"; \
		apt-get update >/dev/null; \
		# Necessary for msodbcsql17 (MSSQL)
		ACCEPT_EULA=Y \
		apt-get -y --no-install-recommends install >/dev/null \
			$buildDeps \
			msodbcsql17 \
		;\
		pecl update-channels; \
		pecl install >/dev/null </dev/null \
			pdo_sqlsrv \
			sqlsrv \
		;\
		docker-php-ext-enable \
			pdo_sqlsrv \
			sqlsrv \
		;\
		# Cleanup
		rm -rf /tmp/pear ~/.pearrc; \
		apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
		apt-get clean; rm -rf /var/lib/apt/lists/*; \
	fi

# PHP tools (installed globally)
ENV COMPOSER_DEFAULT_VERSION=2 \
	COMPOSER_VERSION=1.10.22 \
	COMPOSER2_VERSION=2.1.3 \
	DRUSH_VERSION=8.4.8 \
	DRUSH_LAUNCHER_VERSION=0.9.1 \
	DRUPAL_CONSOLE_LAUNCHER_VERSION=1.9.7 \
	WPCLI_VERSION=2.5.0 \
	BLACKFIRE_VERSION=1.49.3 \
	PLATFORMSH_CLI_VERSION=3.66.0 \
	ACQUIA_CLI_VERSION=1.13.0 \
	TERMINUS_VERSION=2.6.0 \
	JQ_VERSION=1.6 \
	YQ_VERSION=4.11.1
RUN set -xe; \
	# Composer 1.x
	curl -fsSL "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" -o /usr/local/bin/composer1; \
	# Composer 2.x
	curl -fsSL "https://github.com/composer/composer/releases/download/${COMPOSER2_VERSION}/composer.phar" -o /usr/local/bin/composer2; \
	# Drush 8 (global fallback)
	curl -fsSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/local/bin/drush8; \
	# Drush Launcher
	curl -fsSL "https://github.com/drush-ops/drush-launcher/releases/download/${DRUSH_LAUNCHER_VERSION}/drush.phar" -o /usr/local/bin/drush; \
	# Drupal Console Launcher
	curl -fsSL "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_LAUNCHER_VERSION}/drupal.phar" -o /usr/local/bin/drupal; \
	# Wordpress CLI
	curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar" -o /usr/local/bin/wp; \
	# Blackfire CLI
	curl -fsSL "https://packages.blackfire.io/binaries/blackfire-agent/${BLACKFIRE_VERSION}/blackfire-cli-linux_${TARGETARCH}" -o /usr/local/bin/blackfire; \
	# Platform.sh CLI
	curl -fsSL "https://github.com/platformsh/platformsh-cli/releases/download/v${PLATFORMSH_CLI_VERSION}/platform.phar" -o /usr/local/bin/platform; \
	# Acquia CLI
	curl -fsSL "https://github.com/acquia/cli/releases/download/${ACQUIA_CLI_VERSION}/acli.phar" -o /usr/local/bin/acli; \
	# Pantheon Terminus
	curl -fsSL "https://github.com/pantheon-systems/terminus/releases/download/${TERMINUS_VERSION}/terminus.phar" -o /usr/local/bin/terminus; \
	# jq (no arm64)
	if [ "${TARGETARCH}" = "amd64" ]; then \
		curl -fsSL "https://github.com/stedolan/jq/releases/download/jq-${JQ_VERSION}/jq-linux64" -o /usr/local/bin/jq; \
		chmod +x /usr/local/bin/jq; \
	fi; \
	# yq
	curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}" -o /usr/local/bin/yq; \
	# Set Default Composer Version
	ln -s /usr/local/bin/composer${COMPOSER_DEFAULT_VERSION} /usr/local/bin/composer; \
	# Make all downloaded binaries executable in one shot
	(cd /usr/local/bin && chmod +x composer1 composer2 drush8 drush drupal wp blackfire platform acli terminus yq);

# Install Python3 from Debian repos
# This adds about 30MB to uncompressed image size.
# TODO: some other dependency in this image installs python2. Which one?
RUN set -xe; \
	apt-get update >/dev/null; \
	apt-get -y --no-install-recommends install >/dev/null \
		python3 \
	;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

# Install Ruby from Debian repos
RUN set -xe; \
	apt-get update >/dev/null; \
	apt-get -y --no-install-recommends install >/dev/null \
		ruby-full \
	;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

# All further RUN commands will run as the "docker" user
USER docker
SHELL ["/bin/bash", "-c"]

# Don't use -x here, as the output may be excessive
RUN set -e; \
	\
	# Set drush8 as a global fallback for Drush Launcher
	echo -e "\n""export DRUSH_LAUNCHER_FALLBACK=/usr/local/bin/drush8" >> $HOME/.profile; \
	# Composer based dependencies
	# Add composer bin project level and global directories to PATH
	# Project level comes first and thus takes precedence over the global one
	echo -e "\n"'export PATH="$PATH:${PROJECT_ROOT:-/var/www}/vendor/bin"' >> $HOME/.profile; \
	echo -e "\n"'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> $HOME/.profile; \
	# Reload updated PATH from profile to make composer/drush/etc. visible below
	. $HOME/.profile; \
	# Drupal Coder & WP Coding Standards w/ a matching version of PHP_CodeSniffer
	composer global require drupal/coder wp-coding-standards/wpcs phpcompatibility/phpcompatibility-wp >/dev/null; \
	# Don't fix the indentation or installed_paths will not be set correctly
	phpcs --config-set installed_paths \
$HOME/.composer/vendor/drupal/coder/coder_sniffer/,\
$HOME/.composer/vendor/wp-coding-standards/wpcs/,\
$HOME/.composer/vendor/phpcompatibility/php-compatibility/PHPCompatibility/,\
$HOME/.composer/vendor/phpcompatibility/phpcompatibility-wp/PHPCompatibilityWP,\
$HOME/.composer/vendor/phpcompatibility/phpcompatibility-paragonie/PHPCompatibilityParagonieRandomCompat; \
	# Cleanup
	composer clear-cache

# Node.js (installed as user)
ENV \
	NVM_VERSION=0.38.0 \
	NODE_VERSION=14.17.3 \
	YARN_VERSION=1.22.10
# Don't use -x here, as the output may be excessive
RUN set -e; \
	# NVM and a defaut Node.js version
	export PROFILE="$HOME/.profile"; \
	curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash >/dev/null; \
	# Reload profile to load nvm (needed by Yarn installation below)
	. $HOME/.profile; \
	# Yarn
	export YARN_PROFILE="$HOME/.profile"; \
	curl -fsSL https://yarnpkg.com/install.sh | bash -s -- --version ${YARN_VERSION} >/dev/null

## Ruby (installed as user) via rvm
## Note: Disabled. rvm + its build dependecies bloat the image (~80MB)
## Debian 10 ships with Ruby 2.5, so we'll stick with that by default.
## It is still possible for the end user to switch to a different Ruby version via rvm.
#ENV \
#	RVM_VERSION_INSTALL=1.29.10 \
#	RUBY_VERSION_INSTALL=2.7.2
## Don't use -x here, as the output may be excessive
#RUN set -e; \
#	# Export ruby gem bin path
#	echo 'export PATH=$PATH:$(ruby -r rubygems -e "puts Gem.user_dir")/bin' >> $HOME/.profile; \
#	. $HOME/.profile; \
#	# Public GPG servers are not realiable, so downloading keys from rvm.io instead.
#	#gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
#	# Import and trust rvm keys
#	# mpapis@gmail.com
#	curl -sSL https://rvm.io/mpapis.asc | gpg --batch --import -; \
#	echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | gpg --batch --import-ownertrust; \
#	# piotr.kuczynski@gmail.com
#	curl -sSL https://rvm.io/pkuczynski.asc | gpg --batch --import -; \
#	echo 7D2BAF1CF37B13E2069D6956105BD0E739499BDB:6: | gpg --batch --import-ownertrust; \
#	\
#	echo 'rvm_autoupdate_flag=0' >> $HOME/.rvmrc; \
#	echo 'rvm_silence_path_mismatch_check_flag=1' >> $HOME/.rvmrc; \
#	curl -fsSL https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION_INSTALL}/binscripts/rvm-installer | bash -s -- --ignore-dotfiles --version ${RVM_VERSION_INSTALL}; \
#	{ \
#		echo ''; \
#		echo 'export PATH="$PATH:$HOME/.rvm/bin"'; \
#		echo '[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"'; \
#	} >> $HOME/.profile; \
#	# Reload $HOME/.profile to apply settings for the current shell
#	. $HOME/.profile; \
#	\
#	# rvm.io does not currently have ruby binaries for Debian 9, so Ruby is compiled from source, which requires a bunch
#	# of extra dependencies installed (rvm installs these automatically), which bloat this image:
#	# rvm/ruby required packages: gawk, automake, bison, libffi-dev, libgdbm-dev, libncurses5-dev, libsqlite3-dev, libtool, libyaml-dev, sqlite3, zlib1g-dev, libgmp-dev, libreadline-dev, libssl-dev
#	rvm install ruby-${RUBY_VERSION_INSTALL}; \
#	rvm use ruby-${RUBY_VERSION_INSTALL} --default; \
#	\
#	gem install --user-install bundler; \
#	# Have bundler install gems locally (./.bundle) by default
#	echo -e "\n"'export BUNDLE_PATH=.bundle' >> $HOME/.profile; \
#	\
#	rvm cleanup all; \
#	rvm gemset globalcache enable

# Python (installed as user) via pyenv
# Note: Disabled. pyenv + its build dependecies bloat the image (~300MB).
# Debian 10 ships with Python 3.7, so we'll stick with that by default.
# It is still possible for the end user to switch to a different python version via pyenv.
#ENV \
#	PYENV_VERSION_INSTALL=1.2.21 \
#	PYTHON_VERSION_INSTALL=3.8.3
#RUN set -xe; \
#	# pyenv requires a bunch of build dependencies installed, which would bloat this image
#	# See https://github.com/pyenv/pyenv/wiki/Common-build-problems#prerequisites
#	sudo apt-get update >/dev/null; \
#	sudo apt-get -y --no-install-recommends install >/dev/null \
#		build-essential libssl-dev zlib1g-dev libbz2-dev \
#		libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
#		xz-utils tk-dev libffi-dev liblzma-dev python-openssl git \
#	;\
#	# Cleanup
#	sudo apt-get clean; sudo rm -rf /var/lib/apt/lists/*; \
#	\
#	git clone --depth 1 -b v${PYENV_VERSION_INSTALL} https://github.com/pyenv/pyenv.git $HOME/.pyenv; \
#	rm -rf $HOME/.pyenv/.git; \
#	{ \
#		echo ''; \
#		echo 'export PYENV_ROOT="$HOME/.pyenv"'; \
#		echo 'export PATH="$PYENV_ROOT/bin:$PATH"'; \
#		echo 'eval "$(pyenv init -)"'; \
#	} >> $HOME/.profile; \
#	# Reload $HOME/.profile to apply settings for the current shell
#	. $HOME/.profile; \
#	pyenv install ${PYTHON_VERSION_INSTALL}; \
#	pyenv global ${PYTHON_VERSION_INSTALL}

# Notify web container about started fin exec
RUN echo '(/opt/ping-web.sh &)' >> $HOME/.profile

USER root
SHELL ["/bin/sh", "-c"]

# Copy configs and scripts
COPY --chown=docker:docker config/.terminus /home/docker/.terminus
COPY --chown=docker:docker config/.ssh /home/docker/.ssh
COPY config/supervisor /etc/supervisor/conf.d
COPY startup.sh /opt/startup.sh
COPY healthcheck.sh /opt/healthcheck.sh
COPY ping-web.sh /opt/ping-web.sh
# PHP default settings, global overrides and fpm overrides
# PHP_VERSION is set upstream. The source code for the exact PHP version may not be available in Github
# TODO: For now, will just hardcode a specific version available on https://github.com/php/php-src/
ADD https://raw.githubusercontent.com/php/php-src/php-7.3.24/php.ini-development /usr/local/etc/php/php.ini
COPY config/php/zz-php.ini /usr/local/etc/php/conf.d/zz-php.ini
COPY config/php/xdebug.ini /opt/docker-php-ext-xdebug.ini
COPY config/php/xhprof.ini /opt/docker-php-ext-xhprof.ini
COPY config/php/zz-php-fpm.conf /usr/local/etc/php-fpm.d/zz-php-fpm.conf

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
	# Delay in seconds between pings web from cli, while running fin exec. 0 - disabled
	WEB_KEEPALIVE=0 \
	# xdebug disabled by default
	XDEBUG_ENABLED=0 \
	XHPROF_ENABLED=0 \
	XHPROF_OUTPUT_DIR=/tmp/xhprof

# TODO: [v3] remove and set these via docker-compose
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


# Visual Studio Code Server flavor
FROM cli as code-server

# Run as docker, so we don't have to fix permissions
USER docker

ARG HOME=/home/docker

ENV \
	CODE_SERVER_VERSION=3.7.4 \
	VSCODE_HOME="${HOME}/code-server" \
	VSCODE_EXT_DIRECTORY="${HOME}/code-server/extensions" \
	VSCODE_XDEBUG_VERSION=1.13.0 \
	VSCODE_GITLENS_VERSION=11.0.6

# Install code-server
RUN \
	set -xe; \
	curl -fsSL "https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_${TARGETARCH}.deb" -o /tmp/code-server_${TARGETARCH}.deb; \
	sudo dpkg -i /tmp/code-server_${TARGETARCH}.deb; \
	rm -rf /tmp/*.*

# Settings and scripts
COPY --chown=docker:docker opt/code-server /opt/code-server

# Install extensions
RUN \
	set -xe; \
	mkdir -p ${VSCODE_EXT_DIRECTORY}; \
	/opt/code-server/install-vscode-extension https://github.com/felixfbecker/vscode-php-debug/releases/download/v${VSCODE_XDEBUG_VERSION}/php-debug.vsix felixfbecker.php-debug-${VSCODE_XDEBUG_VERSION}; \
	/opt/code-server/install-vscode-extension https://github.com/eamodio/vscode-gitlens/releases/download/v${VSCODE_GITLENS_VERSION}/gitlens-${VSCODE_GITLENS_VERSION}.vsix eamodio.gitlens-${VSCODE_GITLENS_VERSION}

# Switch back to root (IMPORTANT!)
USER root
