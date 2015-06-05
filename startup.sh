#!/bin/bash

# Copy SSH keys from host if available
# First see if we have a mount at /.ssh
if [ -f  /.ssh/id_rsa ]; then
  cp /.ssh/id_rsa* ~/.ssh/
# Otherwise copy from ~/.ssh if available
elif [ -f  ~/.ssh/id_rsa ]; then
  cp /.ssh/id_rsa* ~/.ssh/
fi

# Execute passed CMD arguments
exec "$@"
