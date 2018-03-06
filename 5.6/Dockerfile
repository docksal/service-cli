# Build mhsendmail
FROM golang:1.8.3 as mhbuild
ENV MHSENDMAIL_VERSION=0.2.0
RUN set -xe; \
  go get -d github.com/mailhog/mhsendmail; \
  cd /go/src/github.com/mailhog/mhsendmail; \
  git checkout tags/v${MHSENDMAIL_VERSION}; \
  go get github.com/mailhog/mhsendmail

# Build the image
FROM php:5.6-fpm

ARG DEBIAN_FRONTEND=noninteractive

# Prevent services autoload (http://jpetazzo.github.io/2013/10/06/policy-rc-d-do-not-start-services-automatically/)
RUN set -xe; \
	echo '#!/bin/sh\nexit 101' > /usr/sbin/policy-rc.d && chmod +x /usr/sbin/policy-rc.d

# Install basic packages
RUN set -xe; \
	apt-get update >/dev/null; apt-get -y --force-yes --no-install-recommends install >/dev/null \
		apt-transport-https \
		ca-certificates \
		curl \
		locales \
		wget \
	;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

# Set timezone and locale
RUN set -xe; \
	dpkg-reconfigure locales; \
	locale-gen C.UTF-8; \
	/usr/sbin/update-locale LANG=C.UTF-8
ENV LC_ALL C.UTF-8

# Enable additional repos
RUN set -xe; \
	sed -i 's/main/main contrib non-free/' /etc/apt/sources.list; \
	# Include backports
	echo "deb http://ftp.debian.org/debian jessie-backports main" | tee /etc/apt/sources.list.d/backports.list; \
	# Include blackfire.io repo
	curl -sSL https://packagecloud.io/gpg.key | apt-key add -; \
	echo "deb https://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list; \
	# Include git-lfs repo
	curl -sSL https://packagecloud.io/github/git-lfs/gpgkey | apt-key add -; \
	echo 'deb https://packagecloud.io/github/git-lfs/debian/ jessie main' > /etc/apt/sources.list.d/github_git-lfs.list; \
	echo 'deb-src https://packagecloud.io/github/git-lfs/debian/ jessie main' >> /etc/apt/sources.list.d/github_git-lfs.list; \
	# Including yarn repo
	curl -sSL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -; \
	echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Additional packages
RUN set -xe; \
	apt-get update >/dev/null; apt-get -y --force-yes --no-install-recommends install >/dev/null \
		dnsutils \
		git-lfs \
		ghostscript \
		# html2text binary - used for self-testing (php-fpm)
		html2text \
		imagemagick \
		less \
		# cgi-fcgi binary - used for self-testing (php-fpm)
		libfcgi0ldbl \
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
	;\
	# More recent version of git to get composer's git cache.
	apt-get -y --force-yes --no-install-recommends -t jessie-backports install git >/dev/null ;\
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

RUN set -xe; \
	# Create a regular user/group "docker" (uid = 1000, gid = 1000 ) with access to sudo
	groupadd docker -g 1000; \
	useradd -m -s /bin/bash -u 1000 -g 1000 -G sudo -p docker docker; \
	echo 'docker ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Install gosu and give access to the docker user primary group to use it.
# gosu is used instead of sudo to start the main container process (pid 1) in a docker friendly way.
# https://github.com/tianon/gosu
RUN set -xe; \
	curl -sSL "https://github.com/tianon/gosu/releases/download/1.10/gosu-$(dpkg --print-architecture)" -o /usr/local/bin/gosu; \
	chown root:"$(id -gn docker)" /usr/local/bin/gosu; \
	chmod +sx /usr/local/bin/gosu

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

# Install PHP extentions
RUN set -xe; \
	buildDeps=" \
		g++ \
		libfreetype6-dev \
		libgpgme11-dev \
		libicu-dev \
		libjpeg62-turbo-dev \
		libldap2-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmcrypt-dev \
		libmemcached-dev \
		libmhash-dev \
		libpng12-dev \
		libssh2-1-dev \
		libxslt1-dev \
		zlib1g-dev \
	"; \
	apt-get update >/dev/null; apt-get -y --force-yes --no-install-recommends install >/dev/null \
		$buildDeps \
		blackfire-php \
		libfreetype6 \
		libgpgme11 \
		libicu52 \
		libjpeg62-turbo \
		libldap-2.4-2 \
		libmagickcore-6.q16-2 \
		libmagickwand-6.q16-2 \
		libmcrypt4 \
		libmhash2 \
		libpng12-0 \
		libssh2-1 \
		libxslt1.1 \
		zlib1g \
	;\
	docker-php-ext-configure >/dev/null hash --with-mhash; \
	docker-php-ext-configure >/dev/null gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/; \
	docker-php-ext-configure >/dev/null ldap --with-libdir=lib/x86_64-linux-gnu/; \
	\
	docker-php-ext-install >/dev/null -j$(nproc) \
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
		mysql \
		mysqli \
		pdo_mysql \
		shmop \
		soap \
		sockets \
		sysvmsg \
		sysvsem \
		sysvshm \
		wddx \
		xsl \
		zip \
	;\
	pecl update-channels; \
	pecl install >/dev/null </dev/null \
		gnupg \
		imagick \
		memcache \
		redis \
		ssh2 \
		xdebug-2.5.5 \
	;\
	docker-php-ext-enable \
		gnupg \
		imagick \
		memcache \
		redis \
		ssh2 \
	;\
	# Disable xdebug by default
	rm -f /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini; \
	# Cleanup
	docker-php-source delete; \
	rm -rf /tmp/pear ~/.pearrc; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	apt-get clean; rm -rf /var/lib/apt/lists/*

# Copy mhsendmail binary from stage 1
COPY --from=mhbuild /go/bin/mhsendmail /usr/local/bin/mhsendmail

ENV COMPOSER_VERSION=1.5.2 \
	DRUSH_VERSION=8.1.13 \
	DRUPAL_CONSOLE_VERSION=1.0.2 \
	WPCLI_VERSION=1.3.0 \
	MG_CODEGEN_VERSION=1.6.4 \
	BLACKFIRE_VERSION=1.14.1
RUN set -xe; \
	# Composer
	curl -sSL "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" -o /usr/local/bin/composer; \
	# Drush 8 (default)
	curl -sSL "https://github.com/drush-ops/drush/releases/download/${DRUSH_VERSION}/drush.phar" -o /usr/local/bin/drush; \
	# Drupal Console
	curl -sSL "https://github.com/hechoendrupal/drupal-console-launcher/releases/download/${DRUPAL_CONSOLE_VERSION}/drupal.phar" -o /usr/local/bin/drupal; \
	# Install wp-cli
	curl -sSL "https://github.com/wp-cli/wp-cli/releases/download/v${WPCLI_VERSION}/wp-cli-${WPCLI_VERSION}.phar" -o /usr/local/bin/wp; \
	# Install magento code generator
	curl -sSL "https://github.com/staempfli/magento2-code-generator/releases/download/${MG_CODEGEN_VERSION}/mg2-codegen.phar" -o /usr/local/bin/mg2-codegen; \
	# Install blackfire cli
	curl -sSL https://packages.blackfire.io/binaries/blackfire-agent/${BLACKFIRE_VERSION}/blackfire-cli-linux_static_amd64 -o /usr/local/bin/blackfire; \
	# Make all binaries executable in one shot
	chmod +x /usr/local/bin/*

# Other language packages and dependencies
RUN set -xe; \
	apt-get update >/dev/null; apt-get -y --force-yes --no-install-recommends install >/dev/null \
		ruby-full \
		rlwrap; \
		#build-essential; \
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

# bundler
RUN gem install bundler >/dev/null
# Home directory for bundle installs
ENV BUNDLE_PATH .bundler

# All further RUN commands will run as the "docker" user
USER docker
ENV HOME /home/docker

# Install nvm and a default node version
ENV NVM_VERSION=0.33.4 \
	NODE_VERSION=6.11.3 \
	NVM_DIR=$HOME/.nvm
# Don't use -x here - node/nvm stuff prints just too much stuff
RUN set -e; \
	curl -sSL https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash; \
	. $NVM_DIR/nvm.sh; \
	nvm install $NODE_VERSION >/dev/null; \
	nvm alias default $NODE_VERSION; \
	# Install global node packages
	npm install -g npm >/dev/null; \
	# Cleanup
	nvm clear-cache && npm cache clear --force; \
	# Fix npm complaining about permissions and not being able to update
	sudo rm -rf $HOME/.config

ENV PATH $PATH:$HOME/.composer/vendor/bin
RUN set -xe; \
	# Add composer bin directory to PATH
	echo "\n"'PATH="$PATH:$HOME/.composer/vendor/bin"' >> $HOME/.profile; \
	# Legacy Drush versions (6 and 7)
	#mkdir $HOME/drush6 && cd $HOME/drush6 && composer require drush/drush:6.*;\
	#mkdir $HOME/drush7 && cd $HOME/drush7 && composer require drush/drush:7.*;\
	#echo "alias drush6='$HOME/drush6/vendor/bin/drush'" >> $HOME/.bash_aliases; \
	#echo "alias drush7='$HOME/drush7/vendor/bin/drush'" >> $HOME/.bash_aliases; \
	echo "alias drush8='/usr/local/bin/drush'" >> $HOME/.bash_aliases; \
	# Drush modules
	drush dl registry_rebuild --default-major=7 --destination=$HOME/.drush >/dev/null; \
	drush cc drush; \
	# Drupal Coder w/ a matching version of PHP_CodeSniffer
	composer global require drupal/coder >/dev/null; \
	phpcs --config-set installed_paths $HOME/.composer/vendor/drupal/coder/coder_sniffer; \
	# Composer parallel install plugin
	composer global require hirak/prestissimo >/dev/null; \
	# Cleanup
	composer clear-cache

USER root

# Copy configs and scripts
COPY --chown=docker:docker config/.ssh $HOME/.ssh
COPY --chown=docker:docker config/.drush $HOME/.drush
COPY --chown=docker:docker config/.docksalrc $HOME/.docksalrc
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
