#!/usr/bin/env bash

# Initialization phase in startup.sh is complete
[[ ! -f /var/run/cli ]] && exit 1

# supervisor services are running
if [[ -f /var/run/supervisord.pid ]]; then
	[[ ! -f /var/run/php-fpm.pid ]] && exit 1
	[[ ! -f /var/run/sshd.pid ]] && exit 1
fi

exit 0
