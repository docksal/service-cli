ARG FROM_TAG

FROM docksal/cli:${FROM_TAG}

# Set noninteractive mode during the build (package install) process
ARG DEBIAN_FRONTEND=noninteractive

# Cloud9 IDE and dependencies
RUN set -x; \
	buildDeps=" \
		g++ \
		make \
	";\
	apt-get update; \
	apt-get -y --force-yes --no-install-recommends install >/dev/null \
		$buildDeps \
		tmux \
	;\
	\
	git clone https://github.com/c9/core.git /opt/c9sdk; \
	curl -s -L https://raw.githubusercontent.com/c9/install/master/link.sh | bash; \
	/opt/c9sdk/scripts/install-sdk.sh; \
	rm -rf /opt/c9sdk/.git; \
	chown -R docker:docker /opt/c9sdk; \
	\
	# Cleanup
	rm -rf /tmp/pear ~/.pearrc; \
	apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false $buildDeps >/dev/null; \
	apt-get clean; rm -rf /var/lib/apt/lists/*;

# Launch Cloud9 via supervisord
COPY config/supervisord-cloud9.conf /etc/supervisor/conf.d/cloud9.conf
