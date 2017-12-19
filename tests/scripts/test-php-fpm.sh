#!/usr/bin/env bash

export SCRIPT_FILENAME="/var/www/docroot/${1}"
export REQUEST_URI=/
export QUERY_STRING=
export REQUEST_METHOD=GET

cgi-fcgi -bind -connect 127.0.0.1:9000 | html2text
