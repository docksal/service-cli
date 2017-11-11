#!/usr/bin/env bats

# Debugging
teardown() {
	echo
	# TODO: figure out how to deal with this (output from previous run commands showing up along with the error message)
	echo "Note: ignore the lines between \"...failed\" above and here"
	echo
	echo "Status: $status"
	echo "Output:"
	echo "================================================================"
	echo "$output"
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
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
	fin docker run --name "$NAME" -d -p 19000:9000  \
		"$IMAGE"
	_healthcheck_wait


	### Tests ###

	export SCRIPT_FILENAME=/var/www/index.php
	export REQUEST_URI=/
	export QUERY_STRING=
	export REQUEST_METHOD=GET
	run cgi-fcgi -bind -connect test.docksal:19000
	echo "$output" | grep "X-Powered-By: PHP/5.6"
	echo "$output" | grep "It works!"
	# test some php-fpm ini settings 
	echo "$output" | grep "memory_limit: 256M"
	echo "$output" | grep "sendmail_path: /bin/true"

	export SCRIPT_FILENAME=/var/www/nonsense.php
	run cgi-fcgi -bind -connect test.docksal:19000
	echo "$output" | grep "Status: 404 Not Found"

	run fin docker exec "$NAME" php -m
	echo "$output" | grep "bcmath"
	echo "$output" | grep "blackfire"
	echo "$output" | grep "bz2"
	echo "$output" | grep "calendar"
	echo "$output" | grep "Core"
	echo "$output" | grep "ctype"
	echo "$output" | grep "curl"
	echo "$output" | grep "date"
	echo "$output" | grep "dba"
	echo "$output" | grep "dom"
	echo "$output" | grep "ereg"
	echo "$output" | grep "exif"
	echo "$output" | grep "fileinfo"
	echo "$output" | grep "filter"
	echo "$output" | grep "ftp"
	echo "$output" | grep "gd"
	echo "$output" | grep "gettext"
	echo "$output" | grep "gnupg"
	echo "$output" | grep "hash"
	echo "$output" | grep "iconv"
	echo "$output" | grep "imagick"
	echo "$output" | grep "intl"
	echo "$output" | grep "json"
	echo "$output" | grep "ldap"
	echo "$output" | grep "libxml"
	echo "$output" | grep "mbstring"
	echo "$output" | grep "mcrypt"
	echo "$output" | grep "memcache"
	echo "$output" | grep "mysqlnd"
	echo "$output" | grep "openssl"
	echo "$output" | grep "pcntl"
	echo "$output" | grep "pcre"
	echo "$output" | grep "PDO"
	echo "$output" | grep "pdo_mysql"
	echo "$output" | grep "pdo_sqlite"
	echo "$output" | grep "Phar"
	echo "$output" | grep "posix"
	echo "$output" | grep "readline"
	echo "$output" | grep "redis"
	echo "$output" | grep "Reflection"
	echo "$output" | grep "session"
	echo "$output" | grep "shmop"
	echo "$output" | grep "SimpleXML"
	echo "$output" | grep "soap"
	echo "$output" | grep "sockets"
	echo "$output" | grep "SPL"
	echo "$output" | grep "sqlite3"
	echo "$output" | grep "ssh2"
	echo "$output" | grep "standard"
	echo "$output" | grep "sysvmsg"
	echo "$output" | grep "sysvsem"
	echo "$output" | grep "sysvshm"
	echo "$output" | grep "tokenizer"
	echo "$output" | grep "wddx"
	echo "$output" | grep "xml"
	echo "$output" | grep "xmlreader"
	echo "$output" | grep "xmlwriter"
	echo "$output" | grep "xsl"
	echo "$output" | grep "Zend OPcache"
	echo "$output" | grep "zip"
	echo "$output" | grep "zlib"

	# test some php-cli ini settings
	run fin docker exec "$NAME" php -i
	echo "$output" | grep "memory_limit => 512M => 512M"
	echo "$output" | grep "sendmail_path => /bin/true => /bin/true"

	### Cleanup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
}

@test "Docroot mount" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
	fin docker run --name "$NAME" -d -p 19000:9000  \
		-v $(pwd)/../tests/docroot:/var/www/docroot \
		"$IMAGE"
	_healthcheck_wait


	### Tests ###

	export SCRIPT_FILENAME=/var/www/docroot/test.php
	export REQUEST_URI=/
	export QUERY_STRING=
	export REQUEST_METHOD=GET
	run cgi-fcgi -bind -connect test.docksal:19000
	echo "$output" | grep "X-Powered-By: PHP/5.6"
	echo "$output" | grep "Docroot testing!"

	export SCRIPT_FILENAME=/var/www/docroot/nonsense.php
	run cgi-fcgi -bind -connect test.docksal:19000
	echo "$output" | grep "Status: 404 Not Found"


	### Cleanup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
}


@test "Configuration overrides" {
	[[ $SKIP == 1 ]] && skip

	### Setup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
	fin docker run --name "$NAME" -d -p 19000:9000  \
		-v $(pwd)/../tests/config:/var/www/.docksal/etc/php \
		-e XDEBUG_ENABLED=1 \
		"$IMAGE"
	_healthcheck_wait


	### Tests ###

	export SCRIPT_FILENAME=/var/www/index.php
	export REQUEST_URI=/
	export QUERY_STRING=
	export REQUEST_METHOD=GET
	run cgi-fcgi -bind -connect test.docksal:19000
	echo "$output" | grep "X-Powered-By: PHP/5.6"
	echo "$output" | grep "It works!"
	# test overrides php-fpm ini settings 
	echo "$output" | grep "memory_limit: 512M"
	echo "$output" | grep "sendmail_path: /bin/true"

	# test env variable XDEBUG_ENABLED=true
	run fin docker exec "$NAME" php -m
	echo "$output" | grep "xdebug"

	# test overrides php-cli ini settings
	run fin docker exec "$NAME" php -i
	echo "$output" | grep "memory_limit => 128M => 128M"
	echo "$output" | grep "sendmail_path => /bin/true => /bin/true"

	### Cleanup ###
	fin docker rm -vf "$NAME" >/dev/null 2>&1 || true
}
