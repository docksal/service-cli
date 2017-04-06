#!/bin/bash

HOME_DIR='/home/docker'

DEBUG=${DEBUG:-0}
# Turn debugging ON when cli is started in the service mode
[[ "$1" == "supervisord" ]] && DEBUG=1
echo-debug ()
{
	[[ "$DEBUG" != 0 ]] && echo "$@"
}

# Copy Acquia Cloud API credentials
# @param $1 path to the home directory (parent of the .acquia directory)
copy_dot_acquia ()
{
  local path="${1}/.acquia/cloudapi.conf"
  if [[ -f ${path} ]]; then
    echo-debug "Copying Acquia Cloud API settings in ${path} from host..."
    mkdir -p ${HOME_DIR}/.acquia
    cp ${path} ${HOME_DIR}/.acquia
  fi
}

# Copy Drush settings from host
# @param $1 path to the home directory (parent of the .drush directory)
copy_dot_drush ()
{
  local path="${1}/.drush"
  if [[ -d ${path} ]]; then
    echo-debug "Copying Drush settigns in ${path} from host..."
    cp -r ${path} ${HOME_DIR}
  fi
}

# Copy Acquia Cloud API credentials and Drush settings from host if available
copy_dot_acquia '/.home' # Generic
copy_dot_drush '/.home' # Generic

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
  echo "Enabling xdebug..."
  sudo phpenmod xdebug
fi

# Execute passed CMD arguments
# Service mode (run as root)
if [[ "$1" == "supervisord" ]]; then
	gosu root supervisord
# Command mode (run as docker user)
else
	gosu docker "$@"
fi
