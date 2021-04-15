#!/usr/bin/env bash

# Generates docker images tags for the docker/build-push-action@v2 action depending on the branch/tag.
# Image tag format:
#   develop     => image:[version_prefix][version-]edge[-version_suffix]
#   master      => image:[version_prefix][version][-][version_suffix]
#   semver tag  => image:[version_prefix][version-]major.minor[-version_suffix]

# Example config from build environment
# VERSION_PREFIX = php
# VERSION = 7.4
# VERSION_SUFFIX = ide

# Registries
declare -a registryArr
registryArr+=("docker.io") # Docker Hub
registryArr+=("ghcr.io") # GitHub Container Registry

# Join arguments with hyphen (-) as a delimiter
# Usage: join <arg1> [<argn>]
join() {
	local IFS='-' # join delimiter
	echo "$*"
}

# Image tags
declare -a imageTagArr

# On every build => build / build-sha7
# Latest build tag (used with cache-from)
imageTagArr+=("${IMAGE}:$(join ${VERSION_PREFIX}${VERSION} ${VERSION_SUFFIX} build)")
# Specific build tag - SHA7 (first 7 characters of commit SHA)
imageTagArr+=("${IMAGE}:$(join ${VERSION_PREFIX}${VERSION} ${VERSION_SUFFIX} build ${GITHUB_SHA:1:7})")

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

# Build an array of registry/image:tag values
declare -a repoImageTagArr
for registry in ${registryArr[@]}; do
	for imageTag in ${imageTagArr[@]}; do
		repoImageTagArr+=("${registry}/${imageTag}")
	done
done

# Print with new lines for output in build logs
(IFS=$'\n'; echo "${repoImageTagArr[*]}")
# Using newlines in outputs variables does not seem to work, so we'll use comas
(IFS=$','; echo "::set-output name=tags::${repoImageTagArr[*]}")
