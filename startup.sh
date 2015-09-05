#!/bin/bash

# Copy SSH keys from host if available
# First see if we have a mount at /.ssh
if [ -f  /.ssh/id_rsa ]; then
  cp /.ssh/id_rsa* ~/.ssh/
  chmod 600 ~/.ssh/id_rsa*
# Otherwise copy from /.home/.ssh if available
elif [ -f  /.home/.ssh/id_rsa ]; then
  cp /.home/.ssh/id_rsa* ~/.ssh/
  chmod 600 ~/.ssh/id_rsa*
fi

echo "PHP5-FPM with environment variables"
# Update php5-fpm with access to Docker environment variables
ENV_CONF=/etc/php5/fpm/pool.d/env.conf
echo '[www]' > $ENV_CONF
for var in $(env | awk -F= '{print $1}'); do
	# Skip empty/bad variables as this will blow up PHP FPM.
	if [[ ${!var} == '' || ${var} == '_' ]]; then
		echo "Skipping empty/bad variable: ${var}"
	else
		echo "Adding variable: ${var} = ${!var}"
		echo "env[${var}] = ${!var}" >> $ENV_CONF
	fi
done

# Execute passed CMD arguments
exec "$@"
