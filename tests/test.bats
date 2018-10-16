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
	echo $health_status | grep '"healthy"' >/dev/null 2>&1
}

# Waits for containers to become healthy
# For reasoning why we are not using  `depends_on` `condition` see here:
# https://github.com/docksal/docksal/issues/225#issuecomment-306604063
# TODO: make this universal. Currently hardcoded for cli only.
_healthcheck_wait ()
{
	# Wait for cli to become ready by watching its health status
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
			echo-error "$container_name heathcheck failed" \
				"Container did not enter a healthy state within the expected amount of time." \
				"Try ${yellow}fin restart${NC}"
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
	_healthcheck_wait

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

@test "Bare service" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
	docker run --name "$NAME" -d \
		-v /home/docker \
		-v $(pwd)/../tests/docroot:/var/www/docroot \
		"$IMAGE"
	docker cp $(pwd)/../tests/scripts "$NAME:/var/www/"
	_healthcheck_wait

	### Tests ###

	# Check PHP FPM and settings
	run docker exec -u docker "$NAME" /var/www/scripts/test-php-fpm.sh index.php
	# sed below is used to normalize the web output of phpinfo
	# It will transforms "memory_limit                256M                                         256M" into
	# "memory_limit => 256M => 256M", which is much easier to parse
	output=$(echo "$output" | sed -E 's/[[:space:]]{2,}/ => /g')
	echo "$output" | grep "memory_limit => 256M => 256M"
	# sendmail_path, being long, gets printed on two lines. We grep the first line only
	echo "$output" | grep "sendmail_path => /usr/local/bin/mhsendmail --smtp-addr=mail: /usr/local/bin/mhsendmail --smtp-addr=mail:"
	# Cleanup output after each "run"
	unset output

	run docker exec -u docker "$NAME" /var/www/scripts/test-php-fpm.sh nonsense.php
	echo "$output" | grep "Status: 404 Not Found"
	unset output

	# Check PHP CLI and settings
	phpInfo=$(docker exec -u docker "$NAME" php -i)

	output=$(echo "$phpInfo" | grep "PHP Version")
	echo "$output" | grep "${VERSION}"
	unset output

	output=$(echo "$phpInfo" | grep "memory_limit")
	echo "$output" | grep "memory_limit => 1024M => 1024M"
	unset output

	output=$(echo "$phpInfo" | grep "sendmail_path")
	echo "$output" | grep "sendmail_path => /usr/local/bin/mhsendmail --smtp-addr=mail:1025 => /usr/local/bin/mhsendmail --smtp-addr=mail:1025"
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
	make start -e ENV='-e XDEBUG_ENABLED=1'
	_healthcheck_wait

	### Tests ###

	# Check PHP FPM settings overrides
	run make exec -e CMD='/var/www/scripts/test-php-fpm.sh index.php'
	echo "$output" | grep "memory_limit" | grep "512M"
	unset output

	# Check xdebug was enabled
	run make exec -e CMD='php -m'
	echo "$output" | grep -e "^xdebug$"
	unset output

	# Check PHP CLI overrides
	run make exec -e CMD='php -i'
	echo "$output" | grep "memory_limit => 128M => 128M"
	unset output

	### Cleanup ###
	make clean
}

@test "Check PHP tools and versions" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start
	_healthcheck_wait

	### Tests ###

	# Check Composer version
	run docker exec -u docker "$NAME" bash -lc 'composer --version | grep "^Composer version ${COMPOSER_VERSION} "'
	[[ ${status} == 0 ]]
	unset output

	# Check Drush Launcher version
	run docker exec -u docker "$NAME" bash -lc 'drush --version | grep "^Drush Launcher Version: ${DRUSH_LAUNCHER_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Drush version
	run docker exec -u docker "$NAME" bash -lc 'drush --version | grep "^ Drush Version   :  ${DRUSH_VERSION} $"'
	[[ ${status} == 0 ]]
	unset output

	# Check Drupal Console version
	run docker exec -u docker "$NAME" bash -lc 'drupal --version | grep "^Drupal Console Launcher ${DRUPAL_CONSOLE_LAUNCHER_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Wordpress CLI version
	run docker exec -u docker "$NAME" bash -lc 'wp --version | grep "^WP-CLI ${WPCLI_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Magento 2 Code Generator version
	# TODO: this needs to be replaced with the actual version check
	# See https://github.com/staempfli/magento2-code-generator/issues/15
	#run docker exec -u docker "$NAME" bash -lc 'mg2-codegen --version | grep "^mg2-codegen ${MG_CODEGEN_VERSION}$"'
	run docker exec -u docker "$NAME" bash -lc 'mg2-codegen --version | grep "^mg2-codegen @git-version@$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Terminus version
	run docker exec -u docker "$NAME" bash -lc 'terminus --version | grep "^Terminus ${TERMINUS_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Platform CLI version
	run docker exec -u docker "$NAME" bash -lc 'platform --version | grep "Platform.sh CLI ${PLATFORMSH_CLI_VERSION}"'
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	make clean
}

@test "Check NodeJS tools and versions" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start
	_healthcheck_wait

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

@test "Check misc tools and versions" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	make start
	_healthcheck_wait

	### Tests ###

	# Check Blackfire CLI version
	run docker exec -u docker "$NAME" bash -lc 'blackfire version | grep "^blackfire ${BLACKFIRE_VERSION} "'
	[[ ${status} == 0 ]]
	unset output

	# Check mhsendmail (does not have a flag to report its versions...)
	run docker exec -u docker "$NAME" which mhsendmail
	echo "$output" | grep "/usr/local/bin/mhsendmail"
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
	_healthcheck_wait

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
	_healthcheck_wait

	run docker exec -u docker "${NAME}" cat /tmp/test-startup.txt
	[[ ${status} == 0 ]]
	[[ "${output}" =~ "I ran properly" ]]

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
	_healthcheck_wait

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
	_healthcheck_wait

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
	_healthcheck_wait

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
	_healthcheck_wait

	### Tests ###
	# Confirm output from cron is working

	# Create tmp date file and confirm it's empty
	docker exec -u docker "$NAME" bash -lc 'touch /tmp/date.txt'
	run docker exec -u docker "$NAME" bash -lc 'cat /tmp/date.txt'
	[[ "${output}" == "" ]]
	unset output

	# Sleep for 60+1 seconds so cron can run again.
	sleep 61

	# Confirm cron has ran and file contents has changed
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
	_healthcheck_wait

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
	_healthcheck_wait

	### Tests ###

	# Check PHPCS libraries loaded
	run docker exec -u docker "$NAME" bash -lc 'phpcs -i'
	[[ "${output}" =~ "Drupal, DrupalPractice" ]]
	[[ "${output}" =~ "WordPress-Extra, WordPress-Docs, WordPress, WordPress-VIP and WordPress-Core" ]]
	unset output

	### Cleanup ###
	make clean
}
