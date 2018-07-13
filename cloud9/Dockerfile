ARG FROM_TAG

FROM docksal/cli:${FROM_TAG}

# Set noninteractive mode during the build (package install) process
ARG DEBIAN_FRONTEND=noninteractive

# Run as docker, so we don't have to fix permissions
USER docker

ARG HOME=/home/docker
ENV C9SDK_PATH=$HOME/c9sdk
# Cloud9 IDE and dependencies
RUN \
	# Always source user profile when provisioning as user (necessary for nvm/etc. to load)
	. $HOME/.profile; \
	set -xe; \
	buildDeps=" \
		g++ \
		make \
	";\
	sudo apt-get update; \
	sudo apt-get -y --no-install-recommends install >/dev/null \
		$buildDeps \
		tmux \
	;\
	\
	git clone https://github.com/c9/core.git ${C9SDK_PATH}; \
	curl -s -L https://raw.githubusercontent.com/c9/install/master/link.sh | bash; \
	${C9SDK_PATH}/scripts/install-sdk.sh; \
	\
	# Cleanup
	rm -rf ${C9SDK_PATH}/.git; \
	npm cache clean --force; \
	sudo apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	sudo apt-get clean; \
	sudo rm -rf /var/lib/apt/lists/*;

# Switch back to root (IMPORTANT!)
USER root

# Launch Cloud9 via supervisord
COPY config/supervisord-cloud9.conf /etc/supervisor/conf.d/cloud9.conf
