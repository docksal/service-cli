ARG FROM_TAG

FROM docksal/cli:${FROM_TAG}

# Run as docker, so we don't have to fix permissions
USER docker

ARG HOME=/home/docker

ENV \
	# This is the directory code-server assumes by default
	VSCODE_HOME="${HOME}/.local" \
	VSCODE_SHARE="${HOME}/.local/share/code-server" \
	VSCODE_EXT_DIRECTORY="${HOME}/.local/share/code-server/extensions" \
	CODESERVER_VERSION=1.1156-vsc1.33.1 \
	VSCODE_XDEBUG_VERSION=1.13.0 \
	VSCODE_GITLENS_VERSION=9.9.3

# Install codeserver
RUN \
	set -xe; \
	curl -fsSL "https://github.com/cdr/code-server/releases/download/${CODESERVER_VERSION}/code-server${CODESERVER_VERSION}-linux-x64.tar.gz" -o /tmp/code-server.tar.gz; \
	tar -zxv --file=/tmp/code-server.tar.gz --directory=/tmp --strip-components=1; \
	sudo mv /tmp/code-server /usr/local/bin/; rm -rf /tmp/*.*

# Install extensions
COPY install-vscode-extension /usr/bin/
RUN \
	set -xe; \
	mkdir -p ${VSCODE_EXT_DIRECTORY}; \
	install-vscode-extension https://github.com/felixfbecker/vscode-php-debug/releases/download/v${VSCODE_XDEBUG_VERSION}/php-debug.vsix felixfbecker.php-debug-${VSCODE_XDEBUG_VERSION}; \
	install-vscode-extension https://github.com/eamodio/vscode-gitlens/releases/download/v${VSCODE_GITLENS_VERSION}/gitlens-${VSCODE_GITLENS_VERSION}.vsix eamodio.gitlens-${VSCODE_GITLENS_VERSION}

COPY config/settings.json ${VSCODE_SHARE}/User/settings.json
COPY config/supervisord-codeserver.conf /etc/supervisor/conf.d/codeserver.conf

# Switch back to root (IMPORTANT!)
USER root
