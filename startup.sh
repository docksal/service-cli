#!/bin/bash

# Copy Acquia Cloud API credentials
# @param $1 path to the home directory (parent of the .acquia directory)
copy_dot_acquia ()
{
  local path="${1}/.acquia/cloudapi.conf"
  if [[ -f ${path} ]]; then
    echo "Copying Acquia Cloud API settings in ${path} from host..."
    mkdir -p ~/.acquia
    cp ${path} ~/.acquia
  fi
}

# Copy Drush settings from host
# @param $1 path to the home directory (parent of the .drush directory)
copy_dot_drush ()
{
  local path="${1}/.drush"
  if [[ -d ${path} ]]; then
    echo "Copying Drush settigns in ${path} from host..."
    cp -r ${path} ~
  fi
}

# Copy Acquia Cloud API credentials from host if available
copy_dot_acquia '/.home' # Generic

# Copy Drush settings from host if available
copy_dot_drush '/.home' # Generic

# Reset home directory ownership
sudo chown $(id -u):$(id -g) -R ~

# Enable xdebug
if [[ "${XDEBUG_ENABLED}" == "1" ]]; then
  echo "Enabling xdebug..."
  sudo phpenmod xdebug
fi

# Execute passed CMD arguments
exec "$@"
