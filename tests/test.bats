#!/usr/bin/env bats

# Debugging
teardown() {
	echo
	# TODO: figure out how to deal with this (output from previous run commands showing up along with the error message)
	echo "Note: ignore the lines between \"...failed\" above and here"
	echo
	echo "Status: ${status}"
	echo "Output:"
	echo "================================================================"
	echo "${output}"
	echo "================================================================"
}

# Checks container health status (if available)
# Relies on healchecks introduced in docksal/cli v1.3.0+, uses `sleep` as a fallback
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
	echo ${health_status} | grep '"healthy"' >/dev/null 2>&1
}

# Waits for containers to become healthy
_healthcheck_wait ()
{
	# Wait for cli to become ready by watching its health status
	local container_name="${NAME}"
	local delay=5
	local timeout=30
	local elapsed=0

	until _healthcheck "$container_name"; do
		echo "Waiting for $container_name to become ready..."
		sleep ${delay};

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
		yq \
		zip \
	'

	# Check all binaries in a single shot
	run make exec -e CMD="type $(echo ${binaries} | xargs)"
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Bare service" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
	docker run --name "$NAME" -d \
		-v /home/docker \
		-v $(pwd)/../tests/docroot:/var/www/docroot \
		${IMAGE}:${BUILD_TAG}
	docker cp $(pwd)/../tests/scripts "$NAME:/var/www/"

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check PHP FPM and settings
	# "sed -E 's/[[:space:]]{2,}/ => /g'" - makes the HTML phpinfo output easier to parse. It will transforms
	# "memory_limit                256M                                         256M"
	# into "memory_limit => 256M => 256M", which is much easier to parse
	phpInfo=$(docker exec -u docker "$NAME" bash -c "/var/www/scripts/php-fpm.sh phpinfo.php | sed -E 's/[[:space:]]{2,}/ => /g'")

	output=$(echo "$phpInfo" | grep "memory_limit")
	echo "$output" | grep "256M => 256M"
	unset output

	output=$(echo "$phpInfo" | grep "sendmail_path")
	echo "$output" | grep '/usr/bin/msmtp -t --host=mail --port=1025 => /usr/bin/msmtp -t --host=mail --port=1025'
	unset output

	run docker exec -u docker "$NAME" /var/www/scripts/php-fpm.sh nonsense.php
	echo "$output" | grep "Status: 404 Not Found"
	unset output

	# Check PHP CLI and settings
	phpInfo=$(docker exec -u docker "$NAME" php -i)

	output=$(echo "$phpInfo" | grep "PHP Version")
	echo "$output" | grep "${VERSION}"
	unset output

	# Confirm WebP support enabled for GD
	output=$(echo "$phpInfo" | grep "WebP Support")
	echo "$output" | grep "enabled"
	unset output

	output=$(echo "$phpInfo" | grep "memory_limit")
	# grep expression cannot start with "-", so prepending the expression with "memory_limit" here.
	# Another option is to do "grep -- '-...'".
	echo "$output" | grep "memory_limit => -1 => -1"
	unset output

	output=$(echo "$phpInfo" | grep "sendmail_path")
	echo "$output" | grep '/usr/bin/msmtp -t --host=mail --port=1025 => /usr/bin/msmtp -t --host=mail --port=1025'
	unset output

	# Check PHP modules
	run bash -lc "docker exec -u docker '${NAME}' php -m | diff php-modules.txt -"
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

# Examples of using Makefile commands
# make start, make exec, make clean
@test "Configuration overrides" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start -e ENV='-e XDEBUG_ENABLED=1 -e XHPROF_ENABLED=1'

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check PHP FPM settings overrides
	run make exec -e CMD='/var/www/scripts/php-fpm.sh phpinfo.php'
	echo "$output" | grep "memory_limit" | grep "512M"
	unset output

	# Check xdebug was enabled
	run make exec -e CMD='php -m'
	echo "$output" | grep -e "^xdebug$"
	unset output

	# Check xdebug was enabled
	run make exec -e CMD='php -m'
	echo "$output" | grep -e "^xhprof$"
	unset output

	# Check PHP CLI overrides
	run make exec -e CMD='php -i'
	echo "$output" | grep "memory_limit => 128M => 128M"
	unset output

	# Check Opcache Preload Enabled for 7.4
	run make exec -e CMD='php -i'
	if [[ "${VERSION}" == "7.4" ]]; then echo "$output" | grep "opcache.preload"; fi
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

	# Check Composer v1 version (legacy)
	run docker exec -u docker "$NAME" bash -lc 'set -x; composer1 --version | grep "^Composer version ${COMPOSER_VERSION} "'
	[[ ${status} == 0 ]]
	unset output

	# Check Composer v2 version (default)
	run docker exec -u docker "$NAME" bash -lc 'set -x; composer --version | grep "^Composer version ${COMPOSER2_VERSION} "'
	[[ ${status} == 0 ]]
	unset output

	# Check Drush Launcher version
	run docker exec -u docker "$NAME" bash -lc 'set -x; drush --version | grep "^Drush Launcher Version: ${DRUSH_LAUNCHER_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Drush version
	run docker exec -u docker "$NAME" bash -lc 'set -x; drush --version | grep "^ Drush Version   :  ${DRUSH_VERSION} $"'
	[[ ${status} == 0 ]]
	unset output

	# Check Drupal Console version
	run docker exec -u docker "$NAME" bash -lc 'set -x; drupal --version | grep "^Drupal Console Launcher ${DRUPAL_CONSOLE_LAUNCHER_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Wordpress CLI version
	run docker exec -u docker "$NAME" bash -lc 'set -x; wp --version | grep "^WP-CLI ${WPCLI_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Magento 2 Code Generator version
	# TODO: this needs to be replaced with the actual version check
	# See https://github.com/staempfli/magento2-code-generator/issues/15
	#run docker exec -u docker "$NAME" bash -lc 'mg2-codegen --version | grep "^mg2-codegen ${MG_CODEGEN_VERSION}$"'
	run docker exec -u docker "$NAME" bash -lc 'set -x; mg2-codegen --version | grep "^mg2-codegen @git-version@$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Terminus version
	run docker exec -u docker "$NAME" bash -lc 'set -x; terminus --version | grep "^Terminus ${TERMINUS_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Platform CLI version
	run docker exec -u docker "$NAME" bash -lc 'set -x; platform --version | grep "Platform.sh CLI ${PLATFORMSH_CLI_VERSION}"'
	[[ ${status} == 0 ]]
	unset output

	# Check Acquia CLI version
	run docker exec -u docker "$NAME" bash -lc 'set -x; acli --version | grep "^Acquia CLI ${ACQUIA_CLI_VERSION}$"'
	[[ ${status} == 0 ]]
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

	# nvm
	run docker exec -u docker "$NAME" bash -lc 'nvm --version | grep "${NVM_VERSION}"'
	[[ ${status} == 0 ]]
	unset output

	# nodejs
	run docker exec -u docker "$NAME" bash -lc 'node --version | grep "${NODE_VERSION}"'
	[[ ${status} == 0 ]]
	unset output

	# yarn
	run docker exec -u docker "$NAME" bash -lc 'yarn --version | grep "${YARN_VERSION}"'
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check Ruby tools and versions" {
	skip # TODO: un-skip once Ruby on arm64 works
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# rvm
	run docker exec -u docker "$NAME" bash -lc 'rvm --version 2>&1 | grep "${RVM_VERSION_INSTALL}"'
	[[ ${status} == 0 ]]
	unset output

	# ruby
	run docker exec -u docker "$NAME" bash -lc 'ruby --version | grep "${RUBY_VERSION_INSTALL}"'
	[[ ${status} == 0 ]]
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

	# pyenv
	run docker exec -u docker "$NAME" bash -lc 'pyenv --version 2>&1 | grep "${PYENV_VERSION_INSTALL}"'
	[[ ${status} == 0 ]]
	unset output

	# pyenv
	run docker exec -u docker "$NAME" bash -lc 'python --version 2>&1 | grep "${PYTHON_VERSION_INSTALL}"'
	[[ ${status} == 0 ]]
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
	run docker exec -u docker "$NAME" bash -lc 'blackfire version | grep "^blackfire ${BLACKFIRE_VERSION} "'
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

@test "Check cron" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Give cron 60s to invoke the scheduled test job
	sleep 60
	# Confirm cron has run and file contents has changed
	run docker exec -u docker "$NAME" bash -lc 'tail -1 /tmp/date.txt'
	[[ "${output}" =~ "The current date is " ]]
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
	run docker exec -u docker "$NAME" bash -lc 'git config --get --global user.email'
	[[ "${output}" == "git@example.com" ]]
	unset output

	run docker exec -u docker "$NAME" bash -lc 'git config --get --global user.name'
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
	run docker exec -u docker "$NAME" bash -lc "phpcs -i | sed 's/,//g'"
	# The trailing space below allows comparing all values the same way: " <value> " (needed for the last value to match).
	output="${output} "
	[[ "${output}" =~ " Drupal " ]]
	[[ "${output}" =~ " DrupalPractice " ]]
	[[ "${output}" =~ " WordPress " ]] # Includes WordPress-Core, WordPress-Docs and WordPress-Extra
	[[ "${output}" =~ " PHPCompatibility " ]]
	[[ "${output}" =~ " PHPCompatibilityWP " ]]
	[[ "${output}" =~ " PHPCompatibilityParagonieRandomCompat " ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check Drush Backdrop Commands" {
	[[ $SKIP == 1 ]] && skip
	# Skip until Drush Backdrop is compatible with PHP 7.4
	[[ "$VERSION" == "7.4" ]] && skip

	### Setup ###
	make start

	run _healthcheck_wait
	unset output

	### Tests ###

	# Check Drush Backdrop command loaded
	run docker exec -u docker "$NAME" bash -lc 'drush help backdrop-core-status'
	[[ "${output}" =~ "Provides a birds-eye view of the current Backdrop installation, if any." ]]
	unset output

	### Cleanup ###
	make clean
}

@test "VS Code Server" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start -e ENV='-e IDE_ENABLED=1'

	run _healthcheck_wait
	unset output

	### Tests ###

	run make logs
	echo "$output" | grep 'HTTP server listening on http://0\.0\.0\.0:8080'
	unset output

	### Cleanup ###
	make clean
}
