#!/bin/bash

# This script is running as root by default.
# Switching to the docker user can be done via "gosu docker <command>".

HOME_DIR='/home/docker'

DEBUG=${DEBUG:-0}
# Turn debugging ON when cli is started in the service mode
[[ "$1" == "supervisord" ]] && DEBUG=1
echo-debug ()
{
	[[ "$DEBUG" != 0 ]] && echo "$(date +"%F %H:%M:%S") | $@"
}

uid_gid_reset ()
{
	if [[ "$HOST_UID" != "$(id -u docker)" ]] || [[ "$HOST_GID" != "$(id -g docker)" ]]; then
		echo-debug "Updating docker user uid/gid to $HOST_UID/$HOST_GID to match the host user uid/gid..."
		usermod -u "$HOST_UID" -o docker
		groupmod -g "$HOST_GID" -o "$(id -gn docker)"
	fi
}

xdebug_enable ()
{
	echo-debug "Enabling xdebug..."
	sudo ln -s /opt/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/
}

# Helper function to render configs from go templates using gomplate
render_tmpl ()
{
	local file="${1}"
	local tmpl="${1}.tmpl"

	if [[ -f "${tmpl}" ]]; then
		echo-debug "Rendering template: ${tmpl}..."
		gomplate --file "${tmpl}" --out "${file}"
	else
		echo-debug "Error: Template file not found: ${tmpl}"
		return 1
	fi
}

terminus_login ()
{
	echo-debug "Authenticating with Pantheon..."
	terminus auth:login --machine-token="$SECRET_TERMINUS_TOKEN" >/dev/null 2>&1
}

# Process templates
# Private SSH key
render_tmpl "$HOME_DIR/.ssh/id_rsa"
chmod 0600 "$HOME_DIR/.ssh/id_rsa"
# Acquia Cloud API config
render_tmpl "$HOME_DIR/.acquia/cloudapi.conf"

# Terminus authentication
[[ "$SECRET_TERMINUS_TOKEN" ]] && terminus_login

# Docker user uid/gid mapping to the host user uid/gid
[[ "$HOST_UID" != "" ]] && [[ "$HOST_GID" != "" ]] && uid_gid_reset

# Enable xdebug
[[ "$XDEBUG_ENABLED" != "" ]] && [[ "$XDEBUG_ENABLED" != "0" ]] && xdebug_enable

# Make sure permissions are correct (after uid/gid change and COPY operations in Dockerfile)
# To not bloat the image size, permissions on the home folder are reset at runtime.
echo-debug "Resetting permissions on $HOME_DIR and /var/www..."
chown "$HOST_UID:$HOST_GID" -R "$HOME_DIR"
# Docker resets the project root folder permissions to 0:0 when cli is recreated (e.g. an env variable updated).
# We apply a fix/workaround for this at startup.
chown "$HOST_UID:$HOST_GID" /var/www

# Initialization steps completed. Create a pid file to mark the container as healthy
echo-debug "Preliminary initialization completed"
touch /var/run/cli

# Execute passed CMD arguments
echo-debug "Executing the requested command..."
# Service mode (run as root)
if [[ "$1" == "supervisord" ]]; then
	exec gosu root supervisord -c /etc/supervisor/conf.d/supervisord.conf
# Command mode (run as docker user)
else
	# This makes sure the environment is set up correctly for the docker user
	DOCKSALRC='source $HOME/.docksalrc >/dev/null 2>&1'
	# Launch the passed command in an non-interactive bash session under docker user
	# $@ does not work here. $* has to be used.
	exec gosu docker bash -c "$DOCKSALRC; exec $*"
fi
