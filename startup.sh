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
		usermod -u "$HOST_UID" -o docker
		groupmod -g "$HOST_GID" -o "$(id -gn docker)"
	fi
}

xdebug_enable()
{
	echo-debug "Enabling xdebug..."
	phpenmod xdebug
}

# Docker user uid/gid mapping to the host user uid/gid
[[ "$HOST_UID" != "" ]] && [[ "$HOST_GID" != "" ]] && uid_gid_reset

# Enable xdebug
[[ "$XDEBUG_ENABLED" != "" ]] && [[ "$XDEBUG_ENABLED" != "0" ]] && xdebug_enable

# Make sure permissions are correct (after uid/gid change and COPY operations in Dockerfile)
# To not bloat the image size permissions on the home folder are reset during image startup (in startup.sh)
echo-debug "Resetting permissions on $HOME_DIR and /var/www..."
chown "$HOST_UID:$HOST_GID" -R "$HOME_DIR"
# Docker resets the project root folder permissions to 0:0 when cli is recreated (e.g. an env variable updated).
# Why apply a fix/woraround for this at startup.
chown "$HOST_UID:$HOST_GID" /var/www

# Initialization steps completed. Create a pid file to mark the container is healthy
echo-debug "Preliminary initialization completed"
touch /var/run/cli

# Execute passed CMD arguments
echo-debug "Executing the requested command..."
# Service mode (run as root)
if [[ "$1" == "supervisord" ]]; then
	gosu root supervisord -c /etc/supervisor/conf.d/supervisord.conf
# Command mode (run as docker user)
else
	gosu docker "$@"
fi
