#!/bin/bash

HOME_DIR='/home/docker'

DEBUG=${DEBUG:-0}
# Turn debugging ON when cli is started in the service mode
[[ "$1" == "supervisord" ]] && DEBUG=1
echo-debug ()
{
	[[ "$DEBUG" != 0 ]] && echo "$@"
}

## Docker user uid/gid mapping to the host user uid/gid
if [[ "$HOST_UID" != "" ]] && [[ "$HOST_GID" != "" ]]; then
	if [[ "$HOST_UID" != "$(id -u docker)" ]] || [[ "$HOST_GID" != "$(id -g docker)" ]]; then
		echo-debug "Updating docker user uid/gid to $HOST_UID/$HOST_GID to match the host user uid/gid..."
		sudo usermod -u "$HOST_UID" -o docker >/dev/null 2>&1
		sudo groupmod -g "$HOST_GID" -o users >/dev/null 2>&1
		# Make sure permissions are correct after the uid/gid change
		sudo chown "$HOST_UID:$HOST_GID" -R ${HOME_DIR}
		sudo chown "$HOST_UID:$HOST_GID" /var/www
	fi
fi

# Enable xdebug
if [[ "${XDEBUG_ENABLED}" == "1" ]]; then
  echo-debug "Enabling xdebug..."
  sudo php5enmod xdebug
fi

# Execute passed CMD arguments
# Service mode (run as root)
if [[ "$1" == "supervisord" ]]; then
	gosu root supervisord
# Command mode (run as docker user)
else
	gosu docker "$@"
fi
