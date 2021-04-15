#!/usr/bin/env bash

# Deletes an image tag from Docker Hub
#
# Expects USER, PASSWORD
# Expects IMAGE:TAG as argument.
#
# Example: docker-tag-delete.sh docksal/cli:php7.3-build-01c92a2-amd64

# Credit:
# https://devopsheaven.com/docker/dockerhub/2018/04/09/delete-docker-image-tag-dockerhub.html

set -euo pipefail

# Get IMAGE and TAG from first argument
if [[ "${1}" == "" ]]; then
	echo "Usage: ${0} image:tag"
	exit 1
else
	# Split image:tag
	IFS=$':' read IMAGE TAG <<< ${1};
	# Remove registry prefix from image if present
	IMAGE=${IMAGE#"docker.io/"}
fi

login_data() {
cat <<EOF
{
  "username": "${DOCKERHUB_USERNAME}",
  "password": "${DOCKERHUB_PASSWORD}"
}
EOF
}

# Get auth token
TOKEN=$(curl -s -H "Content-Type: application/json" -X POST -d "$(login_data)" "https://hub.docker.com/v2/users/login/" | jq -r .token)

# Delete tag
output=$(curl -sI "https://hub.docker.com/v2/repositories/${IMAGE}/tags/${TAG}/" \
	-H "Authorization: JWT ${TOKEN}" \
	-X DELETE
)

# Return and error if HTTP response code is not 204
echo "${output}" | grep "HTTP/1.1 204 NO CONTENT"
