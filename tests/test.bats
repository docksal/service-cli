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
	run docker exec "$NAME" /var/www/scripts/test-php-fpm.sh index.php
	echo "$output" | grep "memory_limit" | grep "256M"
	echo "$output" | grep "sendmail_path" | grep "/bin/true"

	run docker exec "$NAME" /var/www/scripts/test-php-fpm.sh nonsense.php
	echo "$output" | grep "Status: 404 Not Found"

	# Check PHP CLI and settings
	phpInfo=$(docker exec "$NAME" php -i)

	output=$(echo "$phpInfo" | grep "PHP Version")
	echo "$output" | grep "${PHP_VERSION}"

	output=$(echo "$phpInfo" | grep "memory_limit")
	echo "$output" | grep "memory_limit => 512M => 512M"

	output=$(echo "$phpInfo" | grep "sendmail_path")
	echo "$output" | grep "sendmail_path => /bin/true => /bin/true"

	# Check PHP modules
	run bash -c "docker exec '${NAME}' php -m | diff php-modules.txt -"
	[[ ${status} == 0 ]]

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
	run docker exec "$NAME" /var/www/scripts/test-php-fpm.sh index.php
	echo "$output" | grep "memory_limit" | grep "512M"

	# Check xdebug was enabled
	run docker exec "$NAME" php -m
	echo "$output" | grep "xdebug"

	# Check PHP CLI overrides
	run docker exec "$NAME" php -i
	echo "$output" | grep "memory_limit => 128M => 128M"

	### Cleanup ###
	docker rm -vf "$NAME" >/dev/null 2>&1 || true
}
