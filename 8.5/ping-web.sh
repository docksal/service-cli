#!/bin/bash

# Notify web container about started fin exec
if [[ "${WEB_KEEPALIVE}" != "0" ]] && [[ "${VIRTUAL_HOST}" != "" ]]
then
	while true
	do
		curl -s -m 1 ${VIRTUAL_HOST}/exec_in_progress_inside_cli >/dev/null 2>&1
		sleep ${WEB_KEEPALIVE}
	done
fi
