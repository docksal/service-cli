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
	sudo apt-get update; \
	sudo apt-get -y --no-install-recommends install >/dev/null \
		tmux \
	;\
	\
	# Cloud9 installation is a mess.
	# Using the installer script on its own results in "unable to install pty.js module" at runtime.
	# This can be addressed by using the link.sh script, however
	# link.sh fails if c9/core is installed in ~/.c9. It complains but then works fine if another directory is used (e.g. ~/c9sdk)
	# So we end up with c9 stuff installed in two places (~/.c9 and ~/c9sdk), but at least it works this way.
	# TODO: revise c9 installation
	git clone --depth=1 https://github.com/c9/core.git ${C9SDK_PATH} >/dev/null; \
	curl -s -L https://raw.githubusercontent.com/c9/install/master/link.sh | bash; \
	${C9SDK_PATH}/scripts/install-sdk.sh >/dev/null; \
	\
	# Cleanup
	# This saves ~30MB of space. c9 throws some non-critical errors during startup (but still works).
	# TODO: may need to revise this
	rm -rf ${C9SDK_PATH}/.git; \
	npm cache clean --force; \
	sudo apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	sudo apt-get clean; \
	sudo rm -rf /var/lib/apt/lists/*;

# Switch back to root (IMPORTANT!)
USER root

# Launch Cloud9 via supervisord
COPY config/supervisord-cloud9.conf /etc/supervisor/conf.d/cloud9.conf
