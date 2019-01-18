#!/bin/bash

# Helper function to render configs from go templates using gomplate
render_tmpl ()
{
	local file="${1}"
	local tmpl="${1}.tmpl"

	if [[ -f "${tmpl}" ]]; then
		echo_debug "Rendering template: ${tmpl}..."
		gomplate --file "${tmpl}" --out "${file}"
	else
		echo_debug "Error: Template file not found: ${tmpl}"
		return 1
	fi
}

# Enable xdebug if requested
xdebug_settings ()
{
	if [[ "$XDEBUG_ENABLED" == "" ]] || [[ "$XDEBUG_ENABLED" == "0" ]]; then return; fi

	echo_debug "Enabling xdebug..."
	ln -s /opt/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/
}

# Inject a private SSH key if provided
ssh_settings ()
{
	[[ "$SECRET_SSH_PRIVATE_KEY" == "" ]] && return

	echo_debug "Adding a private SSH key from SECRET_SSH_PRIVATE_KEY..."
	render_tmpl "$HOME_DIR/.ssh/id_rsa"
	chmod 0600 "$HOME_DIR/.ssh/id_rsa"
	chown docker:docker -R "$HOME_DIR/.ssh"
}

# Helper function to loop through all environment variables prefixed with SECRET_ and
# convert to the equivalent variable without SECRET.
# Example: SECRET_TERMINUS_TOKEN => TERMINUS_TOKEN.
convert_secrets ()
{
	eval 'secrets=(${!SECRET_@})'
	for secret_key in "${secrets[@]}"; do
		key=${secret_key#SECRET_}
		secret_value=${!secret_key}

		# Write new variables to /etc/profile.d/secrets.sh to make them available for all users/sessions
		echo "export ${key}=\"${secret_value}\"" | tee -a "/etc/profile.d/secrets.sh" >/dev/null

		# Also export new variables here
		# This makes them available in the server/php-fpm environment
		eval "export ${key}=${secret_value}"
	done
}

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

# Cron settings
cron_settings ()
{
	# If crontab file is found within project add contents to user crontab file.
	if [[ -f ${PROJECT_ROOT}/.docksal/services/cli/crontab ]]; then
		echo_debug "Loading crontab..."
		cat ${PROJECT_ROOT}/.docksal/services/cli/crontab | crontab -u docker -
	fi
}

# Git settings
git_settings ()
{
	if [[ "$GIT_USER_EMAIL" == "" ]] || [[ "$GIT_USER_NAME" == "" ]]; then return; fi

	# These must be run as the docker user
	echo_debug "Configuring git..."
	su -l docker -c "git config --global user.email '${GIT_USER_EMAIL}'"
	su -l docker -c "git config --global user.name '${GIT_USER_NAME}'"
}

# --- RUNTIME STARTS HERE --- #

ssh_settings
git_settings
xdebug_settings

convert_secrets

acquia_login
terminus_login
cron_settings

# Initialization steps completed. Create a pid file to mark the container as healthy
echo_debug "Preliminary initialization completed."

# Execute a custom startup script if present
if [[ -x ${PROJECT_ROOT}/.docksal/services/cli/startup.sh ]]; then
	echo_debug "Running custom startup script..."
	# TODO: should we source the script instead?
	su -l docker -c "${PROJECT_ROOT}/.docksal/services/cli/startup.sh"
	if [[ $? == 0 ]]; then
		echo_debug "Custom startup script executed successfully."
	else
		echo_debug "ERROR: Custom startup script execution failed."
	fi
fi
