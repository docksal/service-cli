#!/bin/bash

# This script is running as root by default.
# Switching to the docker user can be done via "gosu docker <command>".

HOME_DIR='/home/docker'

DEBUG=${DEBUG:-0}
# Turn debugging ON when cli is started in the service mode
[[ "$1" == "supervisord" ]] && DEBUG=1
echo-debug ()
{
	[[ "$DEBUG" != 0 ]] && echo "$@"
}

uid_gid_reset()
{
	if [[ "$HOST_UID" != "$(id -u docker)" ]] || [[ "$HOST_GID" != "$(id -g docker)" ]]; then
		echo-debug "Updating docker user uid/gid to $HOST_UID/$HOST_GID to match the host user uid/gid..."
		usermod -u "$HOST_UID" -o docker >/dev/null 2>&1
		groupmod -g "$HOST_GID" -o users >/dev/null 2>&1
		# Make sure permissions are correct after the uid/gid change
		chown "$HOST_UID:$HOST_GID" -R ${HOME_DIR}
		chown "$HOST_UID:$HOST_GID" -R /var/www
	fi
}

xdebug_enable()
{
	echo "Enabling xdebug..."
	php5enmod xdebug
}

# Docker user uid/gid mapping to the host user uid/gid
# '""' is used as an empty variable designation in yml files (can't used empty vars without warnings from compose)
# TODO: figure out a better way of checking for empty variables
( [[ "$HOST_UID" != '' ]] || [[ "$HOST_UID" != '""' ]] ) &&
	( [[ "$HOST_GID" != '' ]] || [[ "$HOST_GID" != '""' ]] ) &&
	uid_gid_reset

# Enable xdebug
[[ "$XDEBUG_ENABLED" != "0" ]] && xdebug_enable

# Execute passed CMD arguments
# Service mode (run as root)
if [[ "$1" == "supervisord" ]]; then
	gosu root supervisord -c /etc/supervisor/conf.d/supervisord.conf
# Command mode (run as docker user)
else
	gosu docker "$@"
fi
