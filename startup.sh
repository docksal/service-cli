#!/bin/bash

############################################################
# TODO: depricated this in favor of ssh-agent implementation

# Default SSH key name
if [ -z $SSH_KEY_NAME ]; then SSH_KEY_NAME='id_rsa'; fi
echo "Using SSH key name: $SSH_KEY_NAME"

# TODO: depricated this in favor of ssh-agent implementation
# Copy SSH key pairs.
# @param $1 path to .ssh folder
copy_ssh_key ()
{
  local path="$1/$SSH_KEY_NAME"
  if [ -f $path ]; then
    echo "Copying SSH key $path from host..."
    sudo cp $path ~/.ssh/id_rsa
    sudo chmod 600 ~/.ssh/id_rsa
  fi
}

# Copy SSH keys from host if available
copy_ssh_key '/.home/.ssh' # Generic
copy_ssh_key '/.home-linux/.ssh' # Linux (docker-compose)
copy_ssh_key '/.home-b2d/.ssh' # boot2docker (docker-compose)
############################################################

# Copy Acquia Cloud API credentials
# @param $1 path to the home directory (parent of the .acquia directory)
copy_dot_acquia ()
{
  local path="$1/.acquia/cloudapi.conf"
  if [ -f $path ]; then
    echo "Copying Acquia Cloud API settings in $path from host..."
    mkdir -p ~/.acquia
    cp $path ~/.acquia
  fi
}

# Copy Drush settings from host
# @param $1 path to the home directory (parent of the .drush directory)
copy_dot_drush ()
{
  local path="$1/.drush"
  if [ -d $path ]; then
    echo "Copying Drush settigns in $path from host..."
    cp -r $path ~
  fi
}

# Copy Acquia Cloud API credentials from host if available
copy_dot_acquia '/.home' # Generic
copy_dot_acquia '/.home-linux' # Linux (docker-compose)
copy_dot_acquia '/.home-b2d' # boot2docker (docker-compose)

# Copy Drush settings from host if available
copy_dot_drush '/.home' # Generic
copy_dot_drush '/.home-linux' # Linux (docker-compose)
copy_dot_drush '/.home-b2d' # boot2docker (docker-compose)

# Create proxy-socket for ssh-agent
sudo rm ~/.ssh/socket
sudo socat UNIX-LISTEN:~/.ssh/socket,fork UNIX-CONNECT:/.ssh-agent/socket &
sudo chown $(id -u) ~/.ssh/socket

# Reset home directory ownership
sudo chown $(id -u):$(id -g) -R ~

# Enable/disable xdebug
php5query -m xdebug 1>/dev/null; xdebug_status=$?
if [ $XDEBUG_ENABLED -eq 1 ]; then
  if [ $xdebug_status -ne 0 ]; then
    echo "Enabling xdebug..."
    sudo php5enmod xdebug
  fi
else
  if [ $xdebug_status -eq 0 ]; then
    echo "Disabling xdebug..."
    sudo php5dismod xdebug
  fi
fi

# Execute passed CMD arguments
exec "$@"
