#!/bin/bash

# Enable xdebug if requested
xdebug_settings ()
{
	if [[ "$XDEBUG_ENABLED" == "" ]] || [[ "$XDEBUG_ENABLED" == "0" ]]; then return; fi

	echo_debug "Enabling xdebug..."
	ln -s /opt/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/
}

xdebug_settings
