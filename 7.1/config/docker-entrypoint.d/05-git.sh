#!/bin/bash

# Git settings
git_settings ()
{
	if [[ "$GIT_USER_EMAIL" == "" ]] || [[ "$GIT_USER_NAME" == "" ]]; then return; fi

	# These must be run as the docker user
	echo_debug "Configuring git..."
	su -l docker -c "git config --global user.email '${GIT_USER_EMAIL}'"
	su -l docker -c "git config --global user.name '${GIT_USER_NAME}'"
}

git_settings
