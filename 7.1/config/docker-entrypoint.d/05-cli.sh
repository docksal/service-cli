#!/bin/bash






# --- RUNTIME STARTS HERE --- #

#ssh_settings
#git_settings
#xdebug_settings
#
#convert_secrets
#
#acquia_login
#terminus_login

# Initialization steps completed. Create a pid file to mark the container as healthy
#echo_debug "Preliminary initialization completed."

## Execute a custom startup script if present
#if [[ -x ${PROJECT_ROOT}/.docksal/services/cli/startup.sh ]]; then
#	echo_debug "Running custom startup script..."
#	# TODO: should we source the script instead?
#	su -l docker -c "${PROJECT_ROOT}/.docksal/services/cli/startup.sh"
#	if [[ $? == 0 ]]; then
#		echo_debug "Custom startup script executed successfully."
#	else
#		echo_debug "ERROR: Custom startup script execution failed."
#	fi
#fi
