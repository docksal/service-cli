ARG FROM_TAG

FROM docksal/cli:${FROM_TAG}

# Run as docker, so we don't have to fix permissions
USER docker

# Run as docker, so we don't have to fix permissions
USER docker

ARG HOME=/home/docker

ENV \
	# TODO: 2.x versions do not yet work with xdebug
	CODE_SERVER_VERSION=1.1156-vsc1.33.1 \
	VSCODE_HOME="${HOME}/code-server" \
	VSCODE_EXT_DIRECTORY="${HOME}/code-server/extensions" \
	VSCODE_XDEBUG_VERSION=1.13.0 \
	VSCODE_GITLENS_VERSION=9.9.3

# Install code-server
RUN \
	set -xe; \
	curl -fsSL "https://github.com/cdr/code-server/releases/download/${CODE_SERVER_VERSION}/code-server${CODE_SERVER_VERSION}-linux-x64.tar.gz" -o /tmp/code-server.tar.gz; \
	tar -zxv --file=/tmp/code-server.tar.gz --directory=/tmp --strip-components=1; \
	sudo mv /tmp/code-server /usr/local/bin/; rm -rf /tmp/*.*

# Settings and scripts
COPY opt/code-server /opt/code-server

# Install extensions
RUN \
	set -xe; \
	mkdir -p ${VSCODE_EXT_DIRECTORY}; \
	/opt/code-server/install-vscode-extension https://github.com/felixfbecker/vscode-php-debug/releases/download/v${VSCODE_XDEBUG_VERSION}/php-debug.vsix felixfbecker.php-debug-${VSCODE_XDEBUG_VERSION}; \
	/opt/code-server/install-vscode-extension https://github.com/eamodio/vscode-gitlens/releases/download/v${VSCODE_GITLENS_VERSION}/gitlens-${VSCODE_GITLENS_VERSION}.vsix eamodio.gitlens-${VSCODE_GITLENS_VERSION}

# Switch back to root (IMPORTANT!)
USER root
