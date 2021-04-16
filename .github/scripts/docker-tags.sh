#!/usr/bin/env bash

# Generates docker images tags for the docker/build-push-action@v2 action depending on the branch/tag.
# Image tag format:
#   develop     => image:[version_prefix][version-]edge[-version_suffix]
#   master      => image:[version_prefix][version][-][version_suffix]
#   semver tag  => image:[version_prefix][version-]major.minor[-version_suffix]

# Declare expected variables
IMAGE=${IMAGE} # docksal/cli
VERSION_PREFIX=${VERSION_PREFIX} # php
VERSION=${VERSION} # 7.4
VERSION_SUFFIX=${VERSION_SUFFIX} # ide
REGISTRY="${REGISTRY}" # ghcr.io
GITHUB_REF=${GITHUB_REF} # refs/heads/develop, refs/heads/master, refs/tags/v1.0.0

# Join arguments with hyphen (-) as a delimiter
# Usage: join <arg1> [<argn>]
join() {
	local IFS='-' # join delimiter
	echo "$*"
}

# Prints resulting image tags and sets output variable
set_output() {
	local -n inputArr=${1}

	declare -a outputArr
	for imageTag in ${inputArr[@]}; do
		# Prepend registry to imageTag if provided
		[[ "${REGISTRY}" != "" ]] && imageTag="${REGISTRY}/${imageTag}"
		outputArr+=("${imageTag}")
	done

	# Print with new lines for output in build logs
	(IFS=$'\n'; echo "${outputArr[*]}")
	# Using newlines in output variables does not seem to work, so we'll use comas
	(IFS=$','; echo "::set-output name=tags::${outputArr[*]}")
}

# Image tags
declare -a imageTagArr

## On every build => build / build-sha7
## Latest build tag (used with cache-from)
#imageTagArr+=("${IMAGE}:$(join ${VERSION_PREFIX}${VERSION} ${VERSION_SUFFIX} build)")
## Specific build tag - SHA7 (first 7 characters of commit SHA)
#imageTagArr+=("${IMAGE}:$(join ${VERSION_PREFIX}${VERSION} ${VERSION_SUFFIX} build ${GITHUB_SHA:0:7})")

# develop => version-edge
if [[ "${GITHUB_REF}" == "refs/heads/develop" ]]; then
	imageTagArr+=("${IMAGE}:$(join ${VERSION_PREFIX}${VERSION} edge ${VERSION_SUFFIX})")
fi

# master => version
if [[ "${GITHUB_REF}" == "refs/heads/master" ]]; then
	imageTagArr+=("${IMAGE}:$(join ${VERSION_PREFIX}${VERSION} ${VERSION_SUFFIX})")
fi

# tags/v1.0.0 => 1.0
if [[ "${GITHUB_REF}" =~ "refs/tags/" ]]; then
	# Extract version parts from release tag
	IFS='.' read -a release_arr <<< "${GITHUB_REF#refs/tags/}"
	releaseMajor=${release_arr[0]#v*}  # 2.7.0 => "2"
	releaseMinor=${release_arr[1]}  # "2.7.0" => "7"
	imageTagArr+=("${IMAGE}:$(join ${VERSION_PREFIX}${VERSION} ${VERSION_SUFFIX})")
	imageTagArr+=("${IMAGE}:$(join ${VERSION_PREFIX}${VERSION} ${releaseMajor} ${VERSION_SUFFIX})")
	imageTagArr+=("${IMAGE}:$(join ${VERSION_PREFIX}${VERSION} ${releaseMajor}.${releaseMinor} ${VERSION_SUFFIX})")
fi

# Note: imageTagArr is passed as variable name ("reference") and then expanded inside the called function
# See https://stackoverflow.com/questions/16461656/how-to-pass-array-as-an-argument-to-a-function-in-bash/26443029#26443029
# DockerHub tags
set_output imageTagArr
