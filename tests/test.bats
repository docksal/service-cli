#!/usr/bin/env bats

# Debugging
teardown () {
	echo
	echo "Output:"
	echo "================================================================"
	echo "${output}"
	echo "================================================================"
}

# Checks container health status (if available)
# @param $1 container id/name
_healthcheck ()
{
	local health_status
	health_status=$(docker inspect --format='{{json .State.Health.Status}}' "$1" 2>/dev/null)

	# Wait for 5s then exit with 0 if a container does not have a health status property
	# Necessary for backward compatibility with images that do not support health checks
	if [[ $? != 0 ]]; then
		echo "Waiting 10s for container to start..."
		sleep 10
		return 0
	fi

	# If it does, check the status
	echo $health_status | grep '"healthy"' >/dev/null 2>&1
}

# Waits for containers to become healthy
_healthcheck_wait ()
{
	# Wait for container to become ready by watching its health status
	local container_name="${NAME}"
	local delay=5
	local timeout=30
	local elapsed=0

	until _healthcheck "$container_name"; do
		echo "Waiting for $container_name to become ready..."
		sleep "$delay";

		# Give the container 30s to become ready
		elapsed=$((elapsed + delay))
		if ((elapsed > timeout)); then
			echo "$container_name heathcheck failed"
			exit 1
		fi
	done

	return 0
}

# To work on a specific test:
# run `export SKIP=1` locally, then comment skip in the test you want to debug

@test "Essential binaries" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# List of binaries to check
	binaries='\
		cat \
		convert \
		curl \
		dig \
		g++ \
		ghostscript \
		git \
		git-lfs \
		gcc \
		html2text \
		less \
		make \
		mc \
		more \
		mysql \
		nano \
		nslookup \
		ping \
		psql \
		pv \
		rsync \
		sudo \
		unzip \
		wget \
		zip \
	'

	# Check all binaries in a single shot
	run make exec -e CMD="type $(echo ${binaries} | xargs)"
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check PHP tools and versions" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Since tests doing the `[[ ${status} == 0 ]]` check look identical when they fail, we add an extra prefix to make
	# them distinguishable, e.g. `[[ "composer" && ${status} == 0 ]]`

	# Check Composer version
	run make exec -e CMD='composer --version | grep "^Composer version $${COMPOSER_VERSION} "'
	[[ "composer" && ${status} == 0 ]]
	unset output

	# Check Drush Launcher version
	run make exec -e CMD='drush --version | grep "^Drush Launcher Version: $${DRUSH_LAUNCHER_VERSION}$$"'
	[[ "drush launcher" && ${status} == 0 ]]
	unset output

	# Check Drush version
	run make exec -e CMD='drush --version | grep "^ Drush Version   :  $${DRUSH_VERSION} $$"'
	[[ "drush" && ${status} == 0 ]]
	unset output

	# Check Drupal Console version
	run make exec -e CMD='drupal --version | grep "^Drupal Console Launcher $${DRUPAL_CONSOLE_LAUNCHER_VERSION}$$"'
	[[ "drupal console launcher" && ${status} == 0 ]]
	unset output

	# Check Wordpress CLI version
	run make exec -e CMD='wp --version | grep "^WP-CLI $${WPCLI_VERSION}$$"'
	[[ "wp-cli" && ${status} == 0 ]]
	unset output

	# Check Magento 2 Code Generator version
	# TODO: this needs to be replaced with the actual version check
	# See https://github.com/staempfli/magento2-code-generator/issues/15
	#run make exec -e CMD='mg2-codegen --version | grep "^mg2-codegen ${MG_CODEGEN_VERSION}$"'
	run make exec -e CMD='mg2-codegen --version | grep "^mg2-codegen @git-version@$$"'
	[[ "mg2-codegen" && ${status} == 0 ]]
	unset output

	# Check Terminus version
	run make exec -e CMD='terminus --version | grep "^Terminus $${TERMINUS_VERSION}$$"'
	[[ "terminus" && ${status} == 0 ]]
	unset output

	# Check Platform CLI version
	run make exec -e CMD='platform --version | grep "Platform.sh CLI $${PLATFORMSH_CLI_VERSION}$$"'
	[[ "platform-cli" && ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check NodeJS tools and versions" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Since tests doing the `[[ ${status} == 0 ]]` check look identical when they fail, we add an extra prefix to make
	# them distinguishable, e.g. `[[ "nvm" && ${status} == 0 ]]`

	# nvm
	run make exec -e CMD='nvm --version | grep "^$${NVM_VERSION}$$"'
	[[ "nvm" && ${status} == 0 ]]
	unset output

	# nodejs
	run make exec -e CMD='node --version | grep "^v$${NODE_VERSION}$$"'
	[[ "node" && ${status} == 0 ]]
	unset output

	# yarn
	run make exec -e CMD='yarn --version | grep "^$${YARN_VERSION}$$"'
	[[ "yarn" && ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check Ruby tools and versions" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Since tests doing the `[[ ${status} == 0 ]]` check look identical when they fail, we add an extra prefix to make
	# them distinguishable, e.g. `[[ "rvm" && ${status} == 0 ]]`

	# rvm
	# "rvm --version" prints into stderr...
	run make exec -e CMD='rvm --version | grep "^rvm $${RVM_VERSION_INSTALL}"'
	[[ "rvm" && ${status} == 0 ]]
	unset output

	# ruby
	run make exec -e CMD='ruby --version | grep "^ruby $${RUBY_VERSION_INSTALL}"'
	[[ "ruby" && ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check Python tools and versions" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Since tests doing the `[[ ${status} == 0 ]]` check look identical when they fail, we add an extra prefix to make
	# them distinguishable, e.g. `[[ "pyenv" && ${status} == 0 ]]`

	# pyenv
	run make exec -e CMD='pyenv --version | grep "^pyenv $${PYENV_VERSION_INSTALL}$$"'
	[[ "pyenv" && ${status} == 0 ]]
	unset output

	# python (prints its version into stderr)
	run make exec -e CMD='python --version 2>&1 | grep "^Python $${PYTHON_VERSION_INSTALL}"'
	[[ "Python" && ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check misc tools and versions" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check Blackfire CLI version
	run make exec -e CMD='blackfire version | grep "^blackfire ${BLACKFIRE_VERSION} "'
	[[ ${status} == 0 ]]
	unset output

	# Check msmtp
	run docker exec -u docker "$NAME" which msmtp
	echo "$output" | grep "/usr/bin/msmtp"
	unset output

	### Cleanup ###
	make clean
}

@test "Check config templates" {
	[[ $SKIP == 1 ]] && skip

	# Source and allexport (set -a) variables from docksal.env
	set -a; source $(pwd)/../tests/.docksal/docksal.env; set +a

	# Config variables were loaded
	[[ "${SECRET_SSH_PRIVATE_KEY}" != "" ]]

	### Setup ###
	make start -e ENV="-e SECRET_SSH_PRIVATE_KEY"

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check private SSH key
	run make exec -e CMD='echo ${SECRET_SSH_PRIVATE_KEY}'
	[[ "${output}" != "" ]]
	unset output
	# TODO: figure out how to properly use 'make exec' here (escape quotes)
	run docker exec -u docker "${NAME}" bash -lc 'echo "${SECRET_SSH_PRIVATE_KEY}" | base64 -d | diff ${HOME}/.ssh/id_rsa -'
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check custom startup script" {
	[[ $SKIP == 1 ]] && skip

	make start

	run _healthcheck_wait
	unset output

	run docker exec -u docker "${NAME}" cat /tmp/test-startup.txt
	[[ ${status} == 0 ]]
	[[ "${output}" =~ "I ran properly" ]]

	run docker exec -u docker "${NAME}" cat /tmp/test-startup-terminus.txt
	[[ ${status} == 0 ]]
	[[ "${output}" =~ "/home/docker/.composer/vendor/bin/terminus" ]]

	### Cleanup ###
	make clean
}

@test "Check Acquia integration" {
	[[ $SKIP == 1 ]] && skip

	# Confirm secret is not empty
	[[ "${SECRET_ACAPI_EMAIL}" != "" ]]
	[[ "${SECRET_ACAPI_KEY}" != "" ]]

	### Setup ###
	make start -e ENV='-e SECRET_ACAPI_EMAIL -e SECRET_ACAPI_KEY'

	run _healthcheck_wait
	unset output

	### Tests ###

	# Confirm secrets were passed to the container
	run docker exec -u docker "${NAME}" bash -lc 'echo SECRET_ACAPI_EMAIL: ${SECRET_ACAPI_EMAIL}'
	[[ "${output}" == "SECRET_ACAPI_EMAIL: ${SECRET_ACAPI_EMAIL}" ]]
	unset output
	run docker exec -u docker "${NAME}" bash -lc 'echo SECRET_ACAPI_KEY: ${SECRET_ACAPI_KEY}'
	[[ "${output}" == "SECRET_ACAPI_KEY: ${SECRET_ACAPI_KEY}" ]]
	unset output

	# Confirm the SECRET_ prefix was stripped
	run docker exec -u docker "${NAME}" bash -lc 'echo ACAPI_EMAIL: ${SECRET_ACAPI_EMAIL}'
	[[ "${output}" == "ACAPI_EMAIL: ${SECRET_ACAPI_EMAIL}" ]]
	unset output
	run docker exec -u docker "${NAME}" bash -lc 'echo ACAPI_KEY: ${SECRET_ACAPI_KEY}'
	[[ "${output}" == "ACAPI_KEY: ${SECRET_ACAPI_KEY}" ]]
	unset output

	# Confirm authentication works
	run docker exec -u docker "${NAME}" bash -lc 'drush ac-site-list'
	[[ ${status} == 0 ]]
	[[ ! "${output}" =~ "Not authorized" ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check Platform.sh integration" {
	[[ $SKIP == 1 ]] && skip

	# Confirm secret is not empty
	[[ "${SECRET_PLATFORMSH_CLI_TOKEN}" != "" ]]

	### Setup ###
	make start -e ENV='-e SECRET_PLATFORMSH_CLI_TOKEN'

	run _healthcheck_wait
	unset output

	### Tests ###

	# Confirm token was passed to the container
	run docker exec -u docker "${NAME}" bash -lc 'echo SECRET_PLATFORMSH_CLI_TOKEN: ${SECRET_PLATFORMSH_CLI_TOKEN}'
	[[ "${output}" == "SECRET_PLATFORMSH_CLI_TOKEN: ${SECRET_PLATFORMSH_CLI_TOKEN}" ]]
	unset output

	# Confirm the SECRET_ prefix was stripped
	run docker exec -u docker "${NAME}" bash -lc 'echo PLATFORMSH_CLI_TOKEN: ${SECRET_PLATFORMSH_CLI_TOKEN}'
	[[ "${output}" == "PLATFORMSH_CLI_TOKEN: ${SECRET_PLATFORMSH_CLI_TOKEN}" ]]
	unset output

	# Confirm authentication works
	run docker exec -u docker "${NAME}" bash -lc 'platform auth:info -n'
	[[ ${status} == 0 ]]
	[[ ! "${output}" =~ "Invalid API token" ]]
	[[ "${output}" =~ "developer@docksal.io" ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check Pantheon integration" {
	[[ $SKIP == 1 ]] && skip

	# Confirm secret is not empty
	[[ "${SECRET_TERMINUS_TOKEN}" != "" ]]

	### Setup ###
	make start -e ENV='-e SECRET_TERMINUS_TOKEN'

	run _healthcheck_wait
	unset output

	### Tests ###

	# Confirm token was passed to the container
	run docker exec -u docker "${NAME}" bash -lc 'echo SECRET_TERMINUS_TOKEN: ${SECRET_TERMINUS_TOKEN}'
	[[ "${output}" == "SECRET_TERMINUS_TOKEN: ${SECRET_TERMINUS_TOKEN}" ]]
	unset output

	# Confirm the SECRET_ prefix was stripped
	run docker exec -u docker "${NAME}" bash -lc 'echo TERMINUS_TOKEN: ${TERMINUS_TOKEN}'
	[[ "${output}" == "TERMINUS_TOKEN: ${SECRET_TERMINUS_TOKEN}" ]]
	unset output

	# Confirm authentication works
	run docker exec -u docker "${NAME}" bash -lc 'terminus auth:whoami'
	[[ ${status} == 0 ]]
	[[ ! "${output}" =~ "You are not logged in." ]]
	[[ "${output}" =~ "developer@docksal.io" ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Git settings" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start -e ENV='-e GIT_USER_EMAIL=git@example.com -e GIT_USER_NAME="Docksal CLI"'

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check git settings were applied
	run make exec -e CMD='git config --get --global user.email'
	[[ "${output}" == "git@example.com" ]]
	unset output

	run make exec -e CMD='git config --get --global user.name'
	[[ "${output}" == "Docksal CLI" ]]
	unset output

	### Cleanup ###
	make clean
}

@test "PHPCS Coding standards check" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check PHPCS libraries loaded
	# Normalize the output from phpcs -i so it's easier to do matches
	run make exec -e CMD="phpcs -i | sed 's/,//g'"
	output="${output} "
	[[ "${output}" =~ " Drupal " ]]
	[[ "${output}" =~ " DrupalPractice " ]]
	[[ "${output}" =~ " WordPress " ]] # Includes WordPress-Core, WordPress-Docs and WordPress-Extra
	unset output

	### Cleanup ###
	make clean
}

@test "Check Drush Backdrop Commands" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check Drush Backdrop command loaded
	run make exec -e CMD='drush help backdrop-core-status'
	[[ "${output}" =~ "Provides a birds-eye view of the current Backdrop installation, if any." ]]
	unset output

	### Cleanup ###
	make clean
}
