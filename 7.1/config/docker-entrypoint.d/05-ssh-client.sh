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

# Inject a private SSH key if provided
ssh_settings ()
{
	[[ "$SECRET_SSH_PRIVATE_KEY" == "" ]] && return

	echo_debug "Adding a private SSH key from SECRET_SSH_PRIVATE_KEY..."
	render_tmpl "$HOME_DIR/.ssh/id_rsa"
	chmod 0600 "$HOME_DIR/.ssh/id_rsa"
	chown docker:docker -R "$HOME_DIR/.ssh"
}

ssh_settings
