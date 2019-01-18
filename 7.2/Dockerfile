FROM docksal/php:7.2-edge

ARG DEBIAN_FRONTEND=noninteractive
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE=1

# Enable additional repos
RUN set -xe; \
	sed -i 's/main/main contrib non-free/' /etc/apt/sources.list; \
	# blackfire.io repo
	curl -fsSL https://packages.blackfire.io/gpg.key | apt-key add -; \
	echo "deb https://packages.blackfire.io/debian any main" | tee /etc/apt/sources.list.d/blackfire.list; \
	# git-lfs repo
	curl -fsSL https://packagecloud.io/github/git-lfs/gpgkey | apt-key add -; \
	echo 'deb https://packagecloud.io/github/git-lfs/debian stretch main' | tee /etc/apt/sources.list.d/github_git-lfs.list; \
	echo 'deb-src https://packagecloud.io/github/git-lfs/debian stretch main' | tee -a /etc/apt/sources.list.d/github_git-lfs.list

# Install additional packages
RUN set -xe; \
	# Create man directories, otherwise some packages may not install (e.g. postgresql-client)
	# This should be a temporary workaround until fixed upstream: https://github.com/debuerreotype/debuerreotype/issues/10
	for i in $(seq 1 8); do mkdir -p "/usr/share/man/man$i"; done; \
	\
	apt-get update >/dev/null; \
	apt-get install -y --no-install-recommends >/dev/null \
		dnsutils \
		git \
		git-lfs \
		iputils-ping \
		less \
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
		wget \
		zip \
	; \
	# Cleanup
	apt-get clean; rm -rf /var/lib/apt/lists/*

RUN set -xe; \
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
	buildDeps=" \
	"; \
	apt-get update >/dev/null; \
	apt-get install -y --no-install-recommends >/dev/null \
		$buildDeps \
		blackfire-php \
	; \
	pecl update-channels; \
	pecl install >/dev/null </dev/null \
		xdebug \
	; \
	# Use default PHP settings (development)
	cp -f "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"; \
	\
	# Cleanup
	docker-php-source delete; \
	rm -rf /tmp/pear ~/.pearrc; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	apt-get clean; rm -rf /var/lib/apt/lists/*

# PHP tools (installed globally)
ENV COMPOSER_VERSION=1.8.0 \
	DRUSH_VERSION=8.1.18 \
	DRUSH_LAUNCHER_VERSION=0.6.0 \
	DRUPAL_CONSOLE_LAUNCHER_VERSION=1.8.0 \
	WPCLI_VERSION=2.0.1 \
	BLACKFIRE_VERSION=1.22.0 \
	PLATFORMSH_CLI_VERSION=3.38.1
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
	DRUSH_BACKDROP_VERSION=0.1.0
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
	NVM_VERSION=0.34.0 \
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
	RVM_VERSION_INSTALL=1.29.7 \
	RUBY_VERSION_INSTALL=2.6.0
# Don't use -x here, as the output may be excessive
RUN set -e; \
	# Public GPG servers are not realiable, so downloading keys from rvm.io instead.
	#gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
	# Import and trust rvm keys
	# mpapis@gmail.com
	curl -sSL https://rvm.io/mpapis.asc | gpg --batch --import -; \
	echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | gpg --batch --import-ownertrust; \
	# piotr.kuczynski@gmail.com
	curl -sSL https://rvm.io/pkuczynski.asc | gpg --batch --import -; \
	echo 7D2BAF1CF37B13E2069D6956105BD0E739499BDB:6: | gpg --batch --import-ownertrust; \
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
	PYENV_VERSION_INSTALL=1.2.9
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

# Copy configs and scripts
COPY --chown=docker:docker config/.drush /home/docker/.drush
COPY --chown=docker:docker config/.terminus /home/docker/.terminus
COPY --chown=docker:docker config/.ssh /home/docker/.ssh
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# PHP cli and fpm settings overrides
COPY config/php/xdebug.ini /opt/docker-php-ext-xdebug.ini

COPY config/docker-entrypoint.d /etc/docker-entrypoint.d
COPY config/docker-healthcheck.d /etc/docker-healthcheck.d

ENV \
	# ssh-agent proxy socket (requires docksal/ssh-agent)
	SSH_AUTH_SOCK=/.ssh-agent/proxy-socket \
	# Set TERM so text editors/etc. can be used
	TERM=xterm \
	# xdebug disabled by default
	XDEBUG_ENABLED=0

# Expose additional ports
EXPOSE 22
EXPOSE 3000

# Use supervisord to run multiple processes in development
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
