#!/bin/bash

# Pantheon (terminus) login
terminus_login ()
{
	[[ "$TERMINUS_TOKEN" == "" ]] && return

	echo_debug "Authenticating with Pantheon..."
	# This has to be done using the docker user via su to load the user environment
	# Note: Using 'su -l' to initiate a login session and have .profile sourced for the docker user
	local command="terminus auth:login --machine-token='${TERMINUS_TOKEN}'"
	local output=$(su -l docker -c "${command}" 2>&1)
	if [[ $? != 0 ]]; then
		echo_debug "ERROR: Pantheon authentication failed."
		echo
		echo "$output"
		echo
	fi
}

terminus_login
