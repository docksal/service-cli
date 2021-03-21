#!/usr/bin/env bash

# Generates docker images tags for the docker/build-push-action@v2 action depending on the branch/tag.

declare -a registryArr
registryArr+=("docker.io") # Docker Hub
registryArr+=("ghcr.io") # GitHub Container Registry

declare -a imageTagArr

# feature/* => sha-xxxxxxx
# Note: disabled
#if [[ "${GITHUB_REF}" =~ "refs/heads/feature/" ]]; then
#	GIT_SHA7=$(echo ${GITHUB_SHA} | cut -c1-7) # Short SHA (7 characters)
#	imageTagArr+=("${IMAGE}:php${VERSION}-sha-${GIT_SHA7}")
#fi

# develop => version-edge
if [[ "${GITHUB_REF}" == "refs/heads/develop" ]]; then
	imageTagArr+=("${IMAGE}:php${VERSION}-edge")
fi

# master => version
if [[ "${GITHUB_REF}" == "refs/heads/master" ]]; then
	imageTagArr+=("${IMAGE}:php${VERSION}")
fi

# tags/v1.0.0 => 1.0
if [[ "${GITHUB_REF}" =~ "refs/tags/" ]]; then
	# Extract version parts from release tag
	IFS='.' read -a release_arr <<< "${GITHUB_REF#refs/tags/}"
	releaseMajor=${release_arr[0]#v*}  # 2.7.0 => "2"
	releaseMinor=${release_arr[1]}  # "2.7.0" => "7"
	imageTagArr+=("${IMAGE}:php${VERSION}")
	imageTagArr+=("${IMAGE}:php${VERSION}-${releaseMajor}")
	imageTagArr+=("${IMAGE}:php${VERSION}-${releaseMajor}.${releaseMinor}")
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
