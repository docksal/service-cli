#!/bin/bash

# Copy SSH keys from host if available
# First see if we have a mount at /.ssh
if [ -f  /.ssh/id_rsa ]; then
  cp /.ssh/id_rsa* ~/.ssh/
# Otherwise copy from /.ssh-b2d if available
elif [ -f  /.ssh-b2d/id_rsa ]; then
  cp /.ssh-b2d/id_rsa* ~/.ssh/
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
