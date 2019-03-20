ARG FROM_TAG

FROM docksal/cli:${FROM_TAG}

# Set noninteractive mode during the build (package install) process
ARG DEBIAN_FRONTEND=noninteractive

# Run as docker, so we don't have to fix permissions
USER docker

ARG HOME=/home/docker

ENV CODESERVER_VERSION=1.32.0-310 \
		VSCODE_SHARE="/home/docker/.local/share/code-server" \
		VSCODE_EXT_DIRECTORY="${VSCODE_SHARE}/extensions"

ENV VSCODE_XDEBUG_VERSION=1.13.0 \
		VSCODE_GITLENS_VERSION=9.5.1

COPY install-vscode-extension /user/bin/

RUN \
	# Always source user profile when provisioning as user (necessary for nvm/etc. to load)
	. $HOME/.profile; \
	set -xe; \
		# Download Code Server
		wget -O /tmp/codeserver.tar.gz https://github.com/codercom/code-server/releases/download/${CODESERVER_VERSION}/code-server-${CODESERVER_VERSION}-linux-x64.tar.gz; \
		#Install Code server
		sudo tar -xf /tmp/codeserver.tar.gz --strip-components=1 -C /usr/bin/ code-server-${CODESERVER_VERSION}-linux-x64/code-server; \
		# Install Extension Directory
		mkdir -p ${VSCODE_EXT_DIRECTORY}; \
		# Install Backups Directory
		mkdir -p ${VSCODE_SHARE}/Backups/; \
		# Install Extensions
		install-vscode-extension https://github.com/felixfbecker/vscode-php-debug/releases/download/v${VSCODE_XDEBUG_VERSION}/php-debug.vsix felixfbecker.php-debug-${VSCODE_XDEBUG_VERSION}; \
		install-vscode-extension https://github.com/eamodio/vscode-gitlens/releases/download/v${VSCODE_GITLENS_VERSION}/gitlens-${VSCODE_GITLENS_VERSION}.vsix eamodio.gitlens-${VSCODE_GITLENS_VERSION}; \
	sudo apt-get clean; \
	sudo rm -rf /var/lib/apt/lists/*;

# Switch back to root (IMPORTANT!)
USER root

# Launch Codeserver via supervisord
COPY config/supervisord-codeserver.conf /etc/supervisor/conf.d/codeserver.conf
