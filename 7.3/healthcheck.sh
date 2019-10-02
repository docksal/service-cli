#!/usr/bin/env bash

set -e  # Exit on errors

# Initialization phase in startup.sh is complete
# Need to do "|| exit 1" here since "set -e" apparently does not care about tests.
[[ -f /var/run/cli ]] || exit 1

# supervisor services are running
if [[ -f /run/supervisord.pid ]]; then
	if [[ "${IDE_ENABLED}" != "1" ]]; then
		# php-fpm/cli mode
		[[ -f /run/php-fpm.pid ]] || exit 1
		[[ -f /run/sshd.pid ]] || exit 1
	else
		# IDE mode
		ps aux | grep code-server >/dev/null
	fi
fi
