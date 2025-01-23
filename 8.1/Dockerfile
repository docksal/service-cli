FROM php:8.1.28-fpm-bookworm as cli

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
		# Debian ships with MariaDB instead of MySQL
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

# gosu v1.14+ discorages using it as a non-root user (https://github.com/tianon/gosu/issues/11), which we rely on here.
# See https://github.com/tianon/gosu/pull/89/commits/8afd3dec5fb4fe0356e4fb5d358fe235f7311181
# We'll stick with v1.13 for the time being.
# TODO: Replace gosu with sudo/su in startup.sh
ENV \
	GOSU_VERSION=1.13 \
	GOMPLATE_VERSION=3.11.3
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
	# Docker PHP Extension Installer
	curl -sSLf "https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions" -o /usr/local/bin/install-php-extensions \
		&& chmod +x /usr/local/bin/install-php-extensions; \
	# Instal/enable all PHP extensions via mlocati/docker-php-extension-installer
	install-php-extensions \
		# Stock extensions from upstream image
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
		# Pecl extensions
		apcu \
		gnupg \
		imagick \
		memcached \
		redis \
		ssh2 \
		xdebug \
		xhprof \
		# MSSQL PHP client
		pdo_sqlsrv \
		sqlsrv \
	;\
	# Disable xdebug and xhprof by default to avoid performance impact
	# They can be enabled via environment variables at runtime (XDEBUG_ENABLED=1 and XHPROF_ENABLED=1)
	# There is no native "docker-php-ext-disable", so we remove the ini files manually
	rm -f "$PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini"; \
	rm -f "$PHP_INI_DIR/conf.d/docker-php-ext-xhprof.ini"

# PHP tools (installed globally)
ENV \
	COMPOSER_DEFAULT_VERSION=2 \
	COMPOSER_VERSION=1.10.27 \
	COMPOSER2_VERSION=2.8.5 \
	DRUSH_VERSION=8.4.12 \
	DRUPAL_CONSOLE_LAUNCHER_VERSION=1.9.7 \
	WPCLI_VERSION=2.11.0 \
	# platformsh/legacy-cli
	PLATFORMSH_CLI_VERSION=4.22.0 \
	ACQUIA_CLI_VERSION=2.37.0 \
	TERMINUS_VERSION=3.6.1 \
	JQ_VERSION=1.7.1 \
	YQ_VERSION=4.45.1
RUN set -xe; \
	# Composer 1.x
	curl -fsSL "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" -o /usr/local/bin/composer1; \
	# Composer 2.x
	curl -fsSL "https://github.com/composer/composer/releases/download/${COMPOSER2_VERSION}/composer.phar" -o /usr/local/bin/composer2; \
	# Drush 8 (global fallback)
	curl -fsSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/local/bin/drush8; \
	# Drupal Console Launcher
	curl -fsSL "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_LAUNCHER_VERSION}/drupal.phar" -o /usr/local/bin/drupal; \
	# Wordpress CLI
	curl -fsSL "https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar" -o /usr/local/bin/wp; \
	# Platform.sh CLI
	curl -fsSL "https://github.com/platformsh/legacy-cli/releases/download/v${PLATFORMSH_CLI_VERSION}/platform.phar" -o /usr/local/bin/platform; \
	# Acquia CLI
	curl -fsSL "https://github.com/acquia/cli/releases/download/${ACQUIA_CLI_VERSION}/acli.phar" -o /usr/local/bin/acli; \
	# Pantheon Terminus
	curl -fsSL "https://github.com/pantheon-systems/terminus/releases/download/${TERMINUS_VERSION}/terminus.phar" -o /usr/local/bin/terminus; \
	# jq
	curl -fsSL "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-${TARGETARCH}" -o /usr/local/bin/jq; \
	# yq
	curl -fsSL "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_${TARGETARCH}" -o /usr/local/bin/yq; \
	# Set Default Composer Version
	ln -s /usr/local/bin/composer${COMPOSER_DEFAULT_VERSION} /usr/local/bin/composer; \
	# Make all downloaded binaries executable in one shot
	(cd /usr/local/bin && chmod +x composer1 composer2 drush8 drupal wp platform acli terminus jq yq);

# Install Python 3 + pip from Debian repos
RUN set -xe; \
	apt-get update >/dev/null; \
	apt-get -y --no-install-recommends install >/dev/null \
		python3 \
		python3-pip \
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
	# Composer based dependencies
	# Add composer bin project level and global directories to PATH
	# Project level comes first and thus takes precedence over the global one
	echo -e "\n"'export PATH="$PATH:${PROJECT_ROOT:-/var/www}/vendor/bin"' >> $HOME/.profile; \
	echo -e "\n"'export PATH="$PATH:$HOME/.composer/vendor/bin"' >> $HOME/.profile; \
	# Reload updated PATH from profile to make composer/etc. visible below
	. $HOME/.profile; \
	# Drupal Coder & WP Coding Standards w/ a matching version of PHP_CodeSniffer
	# Set allow-plugins. See https://getcomposer.org/allow-plugins
	composer global config allow-plugins.dealerdirect/phpcodesniffer-composer-installer true; \
	composer global require drupal/coder wp-coding-standards/wpcs phpcompatibility/phpcompatibility-wp; \
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
	NVM_VERSION=0.40.1 \
	NODE_VERSION=20.17.0 \
	# Yarn (Classic v1)
	# https://github.com/yarnpkg/yarn/releases
	YARN_VERSION=1.22.22
# Don't use -x here, as the output may be excessive
RUN set -e; \
	# NVM and a defaut Node.js version
	export PROFILE="$HOME/.profile"; \
	curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash >/dev/null; \
	# Reload profile to load nvm (needed by Yarn installation below)
	. $HOME/.profile; \
	# Yarn (Classic v1)
	# Installing via npm to allow fore override with never versions via corepack
	npm install -g yarn@${YARN_VERSION}; \
	# Enable corepack (allows installing project level yarn v2+ via yarn)
	corepack enable

## Ruby bundler
## Don't use -x here, as the output may be excessive
RUN set -e; \
	# Export ruby gem bin path
	echo 'export PATH=$PATH:$(ruby -r rubygems -e "puts Gem.user_dir")/bin' >> $HOME/.profile; \
	. $HOME/.profile; \
	gem install --user-install bundler; \
	# Have bundler install gems in the current directory (./.bundle) by default
	echo -e "\n"'export BUNDLE_PATH=.bundle' >> $HOME/.profile

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
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
COPY config/php/zz-php.ini /usr/local/etc/php/conf.d/zz-php.ini
COPY config/php/xdebug.ini /opt/docker-php-ext-xdebug.ini
COPY config/php/xhprof.ini /opt/docker-php-ext-xhprof.ini
COPY config/php/opcache.ini /opt/docker-php-ext-opcache.ini
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
	CODE_SERVER_VERSION=4.23.1 \
	VSCODE_GITLENS_VERSION=14.9.0 \
	VSCODE_XDEBUG_VERSION=1.34.0 \
	VSCODE_HOME="${HOME}/code-server"

# Install code-server
RUN set -xe; \
	curl -fsSL "https://github.com/cdr/code-server/releases/download/v${CODE_SERVER_VERSION}/code-server_${CODE_SERVER_VERSION}_${TARGETARCH}.deb" -o /tmp/code-server_${TARGETARCH}.deb; \
	sudo dpkg -i /tmp/code-server_${TARGETARCH}.deb; \
	rm -rf /tmp/*.*

# Settings
COPY --chown=docker:docker config/code-server ${VSCODE_HOME}

# Install extensions
# Note: Have to use --user-data-dir with --install-extension instead of --config
RUN set -xe; \
	code-server --user-data-dir=${VSCODE_HOME} --install-extension eamodio.gitlens@${VSCODE_GITLENS_VERSION}; \
	code-server --user-data-dir=${VSCODE_HOME} --install-extension xdebug.php-debug@${VSCODE_XDEBUG_VERSION}

# Switch back to root (IMPORTANT!)
USER root
