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


# Global skip
# Uncomment below, then comment skip in the test you want to debug. When done, reverse.
#SKIP=1

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
	run bash -c "docker exec '${NAME}' php -m | diff php-modules.txt -"
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Configuration overrides" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
	docker run --name "$NAME" -d \
		-v /home/docker \
		-v $(pwd)/../tests:/var/www \
		-e XDEBUG_ENABLED=1 \
		"$IMAGE"
	_healthcheck_wait

	### Tests ###

	# Check PHP FPM settings overrides
	run docker exec -u docker "$NAME" /var/www/scripts/test-php-fpm.sh index.php
	echo "$output" | grep "memory_limit" | grep "512M"
	unset output

	# Check xdebug was enabled
	run docker exec -u docker "$NAME" php -m
	echo "$output" | grep -e "^xdebug$"
	unset output

	# Check PHP CLI overrides
	run docker exec -u docker "$NAME" php -i
	echo "$output" | grep "memory_limit => 128M => 128M"
	unset output

	### Cleanup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Check binaries and versions" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
	docker run --name "$NAME" -d \
		-v /home/docker \
		-v $(pwd)/../tests:/var/www \
		-e XDEBUG_ENABLED=1 \
		"$IMAGE"
	_healthcheck_wait

	### Tests ###

	# Check Composer version
	run docker exec -u docker "$NAME" bash -c 'composer --version | grep "^Composer version ${COMPOSER_VERSION} "'
	[[ ${status} == 0 ]]
	unset output

	# Check Drush Launcher version
	run docker exec -u docker "$NAME" bash -c 'drush --version | grep "^Drush Launcher Version: ${DRUSH_LAUNCHER_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Drush version
	run docker exec -u docker "$NAME" bash -c 'drush --version | grep "^ Drush Version   :  ${DRUSH_VERSION} $"'
	[[ ${status} == 0 ]]
	unset output

	# Check Drupal Console version
	run docker exec -u docker "$NAME" bash -c 'drupal --version | grep "^Drupal Console Launcher ${DRUPAL_CONSOLE_LAUNCHER_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Wordpress CLI version
	run docker exec -u docker "$NAME" bash -c 'wp --version | grep "^WP-CLI ${WPCLI_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Magento 2 Code Generator version
	# TODO: this needs to be replaced with the actual version check
	# See https://github.com/staempfli/magento2-code-generator/issues/15
	#run docker exec -u docker "$NAME" bash -c 'mg2-codegen --version | grep "^mg2-codegen ${MG_CODEGEN_VERSION}$"'
	run docker exec -u docker "$NAME" bash -c 'mg2-codegen --version | grep "^mg2-codegen @git-version@$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Blackfire CLI version
	run docker exec -u docker "$NAME" bash -c 'blackfire version | grep "^blackfire ${BLACKFIRE_VERSION} "'
	[[ ${status} == 0 ]]
	unset output

	# Check mhsendmail (does not have a flag to report its versions...)
	run docker exec -u docker "$NAME" which mhsendmail
	echo "$output" | grep "/usr/local/bin/mhsendmail"
	unset output

	# Check Terminus version
	run docker exec -u docker "$NAME" bash -c 'terminus --version | grep "^Terminus ${TERMINUS_VERSION}$"'
	[[ ${status} == 0 ]]
	unset output

	# Check Platform CLI version
	run docker exec -u docker "$NAME" bash -c 'platform --version | grep "Platform.sh CLI ${PLATFORMSH_CLI_VERSION}"'
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Check config templates" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	cd ../tests
	echo "CLI_IMAGE=\"${IMAGE}\"" > .docksal/docksal-local.env
	fin reset -f

	### Tests ###

	# Load environment variables from docksal.env and confirm then are not empty
	source .docksal/docksal.env
	[[ "${SECRET_ACAPI_EMAIL}" != "" ]]
	[[ "${SECRET_ACAPI_KEY}" != "" ]]
	[[ "${SECRET_SSH_PRIVATE_KEY}" != "" ]]

	# Check Acquia Cloud API conf
	run fin exec 'echo ${SECRET_ACAPI_EMAIL}'
	[[ "${output}" != "" ]]
	unset output
	run fin exec 'echo ${SECRET_ACAPI_KEY}'
	[[ "${output}" != "" ]]
	unset output
	run fin exec 'grep "${SECRET_ACAPI_EMAIL}" "$HOME/.acquia/cloudapi.conf" && grep "${SECRET_ACAPI_KEY}" "$HOME/.acquia/cloudapi.conf"'
	[[ ${status} == 0 ]]
	unset output

	# Check private SSH key
	run fin exec 'echo ${SECRET_SSH_PRIVATE_KEY}'
	[[ "${output}" != "" ]]
	unset output
	run fin exec 'echo "${SECRET_SSH_PRIVATE_KEY}" | diff $HOME/.ssh/id_rsa -'
	[[ ${status} == 0 ]]
	unset output

	### Cleanup ###
	fin rm -f
	rm -f .docksal/docksal-local.env
}

@test "Check Custom Startup Script Works" {
	[[ $SKIP == 1 ]] && skip

	cd ../tests
	echo "CLI_IMAGE=\"${IMAGE}\"" > .docksal/docksal-local.env
	fin reset -f

	run fin exec -T 'cat /tmp/test-startup.txt'
	[[ ${status} == 0 ]] &&
	[[ "${output}" =~ "I ran properly" ]]
}

@test "Check Platform.sh Integration" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
	docker run --name "$NAME" -d \
		-v /home/docker \
		-v $(pwd)/../tests:/var/www \
		-e SECRET_PLATFORMSH_CLI_TOKEN \
		"$IMAGE"
	_healthcheck_wait

	### Tests ###

	# Confirm output is not empty and token is passed to container
	run docker exec -it -u docker "$NAME" bash -c 'source $HOME/.docksalrc >/dev/null 2>&1; echo "${SECRET_PLATFORMSH_CLI_TOKEN}"'
	[[ "${output}" != "" ]]
	unset output

	# Confirm token passed to container was converted without SECRET_
	run fin exec 'echo ${PLATFORMSH_CLI_TOKEN}'
	[[ "${output}" != "" ]]
	unset output

	# Confirm Authentication
	run docker exec -it -u docker "$NAME" bash -c 'source $HOME/.docksalrc >/dev/null 2>&1; platform auth:info -n'
	[[ ${status} == 0 ]] &&
	[[ ! "${output}" =~ "Invalid API token" ]] &&
	[[ "${output}" =~ "Docksal App" ]] &&
	unset output

	### Cleanup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Check Pantheon Integration" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
	docker run --name "$NAME" -d \
		-v /home/docker \
		-v $(pwd)/../tests:/var/www \
		-e SECRET_TERMINUS_TOKEN \
		"$IMAGE"
	_healthcheck_wait

	### Tests ###

	# Confirm output is not empty and token is passed to container
	run docker exec -it -u docker "$NAME" bash -c 'source $HOME/.docksalrc >/dev/null 2>&1; echo "${SECRET_TERMINUS_TOKEN}"'
	[[ "${output}" =~ "${SECRET_TERMINUS_TOKEN}" ]]
	unset output

	# Confirm Authentication
	run docker exec -it -u docker "$NAME" bash -c 'source $HOME/.docksalrc >/dev/null 2>&1; terminus auth:whoami'
	[[ ${status} == 0 ]] &&
	[[ ! "${output}" =~ "You are not logged in." ]] &&
	[[ "${output}" =~ "developer@docksal.io" ]] &&
	unset output

	### Cleanup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Custom Cron Integration" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
	docker run --name "$NAME" -d \
		-v /home/docker \
		-v $(pwd)/../tests:/var/www \
		"$IMAGE"
	_healthcheck_wait

	### Tests ###
	# Confirm output from cron is working

	# Create tmp date file
	docker exec -it -u docker "$NAME" bash -c 'echo "The current date is $(date)" > /tmp/date.txt; chmod 0777 /tmp/date.txt'

	# Confirm File created and exists
	run docker exec -it -u docker "$NAME" bash -c 'cat /tmp/date.txt'
	[[ "${output}" =~ "The current date is " ]]
	OLD_OUTPUT="${output}"
	unset output

	# Sleep for 60 Seconds so cron can run again.
	sleep 60

	# Confirm cron has ran and file contents has changed
	run docker exec -it -u docker "$NAME" bash -c 'cat /tmp/date.txt'
	[[ "${output}" =~ "The current date is " ]]
	NEW_OUTPUT="${output}"
	unset output

	# Confirm First Test is not the same as old test
	[[ "${OLD_OUTPUT}" != "${NEW_OUTPUT}" ]]

	### Cleanup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
}
