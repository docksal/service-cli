#!/bin/bash

# Acquia Cloud API login
acquia_login ()
{
	if [[ "$ACAPI_EMAIL" == "" ]] || [[ "$ACAPI_KEY" == "" ]]; then return; fi

	echo_debug "Authenticating with Acquia..."
	# This has to be done using the docker user via su to load the user environment
	# Note: Using 'su -l' to initiate a login session and have .profile sourced for the docker user
	local command="drush ac-api-login --email='${ACAPI_EMAIL}' --key='${ACAPI_KEY}' --endpoint='https://cloudapi.acquia.com/v1' && drush ac-site-list"
	local output=$(su -l docker -c "${command}" 2>&1)
	if [[ $? != 0 ]]; then
		echo_debug "ERROR: Acquia authentication failed."
		echo
		echo "$output"
		echo
	fi
}

acquia_login
