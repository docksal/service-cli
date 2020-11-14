#!/usr/bin/env bash

# Generates docker images tags for the docker/build-push-action@v2 action depending on the branch/tag.

declare -a IMAGE_TAGS

# feature/* => sha-xxxxxxx
# Note: disabled
#if [[ "${GITHUB_REF}" =~ "refs/heads/feature/" ]]; then
#	GIT_SHA7=$(echo ${GITHUB_SHA} | cut -c1-7) # Short SHA (7 characters)
#	IMAGE_TAGS+=("${REPO}:sha-${GIT_SHA7}-php${VERSION}")
#	IMAGE_TAGS+=("ghcr.io/${REPO}:sha-${GIT_SHA7}-php${VERSION}")
#fi

# develop => edge
if [[ "${GITHUB_REF}" == "refs/heads/develop" ]]; then
	IMAGE_TAGS+=("${REPO}:edge-php${VERSION}")
	IMAGE_TAGS+=("ghcr.io/${REPO}:edge-php${VERSION}")
fi

# master => stable
if [[ "${GITHUB_REF}" == "refs/heads/master" ]]; then
	IMAGE_TAGS+=("${REPO}:stable-php${VERSION}")
	IMAGE_TAGS+=("ghcr.io/${REPO}:stable-php${VERSION}")
fi

# tags/v1.0.0 => 1.0
if [[ "${GITHUB_REF}" =~ "refs/tags/" ]]; then
	# Extract version parts from release tag
	IFS='.' read -a ver_arr <<< "${GITHUB_REF#refs/tags/}"
	VERSION_MAJOR=${ver_arr[0]#v*}  # 2.7.0 => "2"
	VERSION_MINOR=${ver_arr[1]}  # "2.7.0" => "7"
	IMAGE_TAGS+=("${REPO}:stable-php${VERSION}")
	IMAGE_TAGS+=("${REPO}:${VERSION_MAJOR}-php${VERSION}")
	IMAGE_TAGS+=("${REPO}:${VERSION_MAJOR}.${VERSION_MINOR}-php${VERSION}")
	IMAGE_TAGS+=("ghcr.io/${REPO}:stable-php${VERSION}")
	IMAGE_TAGS+=("ghcr.io/${REPO}:${VERSION_MAJOR}-php${VERSION}")
	IMAGE_TAGS+=("ghcr.io/${REPO}:${VERSION_MAJOR}.${VERSION_MINOR}-php${VERSION}")
fi

# Output a comma concatenated list of image tags
IMAGE_TAGS_STR=$(IFS=,; echo "${IMAGE_TAGS[*]}")
echo "${IMAGE_TAGS_STR}"
echo "::set-output name=tags::${IMAGE_TAGS_STR}"
