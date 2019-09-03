#!/bin/bash

# Get the name of the process with pid=1
docker_cmd=$(ps -p 1 -o comm=)

# supervisor services are running
if [[ "${docker_cmd}" == "supervisord" ]]; then
	-f /run/supervisord.pid
	-f /run/php-fpm.pid
	-f /run/sshd.pid
fi
