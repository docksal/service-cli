#!/usr/bin/env bash

export SCRIPT_FILENAME="/var/www/docroot/${1}"
export REQUEST_URI=/
export QUERY_STRING=
export REQUEST_METHOD=GET

# "sed 's/\xC2\xA0/ /g'" - replaces non-breaking spaces (&nbsp) with regular spaces.
# This can be a nightmare to debug, since nbsp's are identical to spaces in a text editor.
# Note: this sed does NOT work on Mac, so make sure it's only run inside a container.
# See https://superuser.com/questions/517847/use-sed-to-replace-nbsp-160-hex-00a0-octal-240-non-breaking-space
# "-width 1024" prevents text wrapping for long values (e.g. sendmail_path)
cgi-fcgi -bind -connect 127.0.0.1:9000 | html2text -width 1024 | sed 's/\xC2\xA0/ /g'
