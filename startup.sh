#!/bin/bash

# Default SSH key name
if [ -z $SSH_KEY_NAME ]; then SSH_KEY_NAME='id_rsa'; fi
echo "Using SSH key name: $SSH_KEY_NAME"

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

# Copy SSH keys from host if available
copy_ssh_key '/.home/.ssh' # Generic
copy_ssh_key '/.home-linux/.ssh' # Linux (docker-compose)
copy_ssh_key '/.home-b2d/.ssh' # boot2docker (docker-compose)

# Copy Acquia Cloud API credentials from host if available
copy_dot_acquia '/.home' # Generic
copy_dot_acquia '/.home-linux' # Linux (docker-compose)
copy_dot_acquia '/.home-b2d' # boot2docker (docker-compose)

# Copy Drush settings from host if available
copy_dot_drush '/.home' # Generic
copy_dot_drush '/.home-linux' # Linux (docker-compose)
copy_dot_drush '/.home-b2d' # boot2docker (docker-compose)

echo "PHP5-FPM with environment variables"
# Update php5-fpm with access to Docker environment variables
ENV_CONF=/etc/php5/fpm/pool.d/env.conf
echo '[www]' | sudo tee $ENV_CONF > /dev/null 2>&1
for var in $(env | awk -F = '{print $1}'); do
  # Skip empty/bad variables as this will blow up PHP FPM.
  if [[ ${!var} == '' || ${var} == '_' ]]; then
    echo "Skipping empty/bad variable: '"${var}"'"
  else
    echo "Adding variable: '"${var}"' = '"${!var}"'"
    echo "env['"${var}"'] = '"${!var}"'" | sudo tee -a $ENV_CONF > /dev/null 2>&1
  fi
done

# Execute passed CMD arguments
exec "$@"
