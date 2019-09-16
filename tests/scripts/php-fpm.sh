#!/usr/bin/env bash

export SCRIPT_FILENAME="/var/www/docroot/${1}"
export REQUEST_URI=/
export QUERY_STRING=
export REQUEST_METHOD=GET

# "sed 's/\xC2\xA0/ /g'" - replaces non-breaking spaces (&nbsp) with regular spaces.
# This can be a nightmare to debug, since nbsp's are identical to spaces in a text editor.
# Note: this sed does NOT work on Mac, so make sure it's only run inside a container.
cgi-fcgi -bind -connect 127.0.0.1:9000 | html2text | sed 's/\xC2\xA0/ /g'
