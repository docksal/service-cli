ARG FROM_TAG

FROM docksal/cli:${FROM_TAG}

# Cloud9 IDE and dependencies
RUN set -x; \
	apt-get update; \
	apt-get install -y tmux g++ make; \
	git clone https://github.com/c9/core.git /opt/c9sdk; \
	curl -s -L https://raw.githubusercontent.com/c9/install/master/link.sh | bash; \
	/opt/c9sdk/scripts/install-sdk.sh; \
	rm -rf /opt/c9sdk/.git; \
	chown -R docker:docker /opt/c9sdk;

# Launch Cloud9 via supervisord
COPY config/supervisord-cloud9.conf /etc/supervisor/conf.d/cloud9.conf
