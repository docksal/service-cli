#!/usr/bin/env bash

# Initialization phase in startup.sh is complete
[[ -f /var/run/cli ]] || exit 1

# supervisor services are running
if [[ -f /run/supervisord.pid ]]; then
	if [[ "${IDE_ENABLED}" == "1" ]]; then
		# IDE mode
		ps aux | grep code-server >/dev/null || exit 1
	else
		# php-fpm/cli mode
		[[ -f /run/php-fpm.pid ]] || exit 1
		[[ -f /run/sshd.pid ]] || exit 1
	fi
fi
