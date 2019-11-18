#!/usr/bin/env bash

# ----- Helper functions ----- #

is_edge ()
{
	[[ "${TRAVIS_BRANCH}" == "develop" ]]
}

is_stable ()
{
	[[ "${TRAVIS_BRANCH}" == "master" ]]
}

is_release ()
{
	[[ "${TRAVIS_TAG}" != "" ]]
}

# Check whether the current build is for a pull request
is_pr ()
{
	[[ "${TRAVIS_PULL_REQUEST}" != "false" ]]
}

is_latest ()
{
	[[ "${VERSION}" == "${LATEST_VERSION}" ]]
}

# Tag and push an image
# $1 - source image
# $2 - target image
tag_and_push ()
{
	local source=$1
	local target=$2

	# Base image
	echo "Pushing ${target} image ..."
	docker tag ${source} ${target}
	docker push ${target}

	# Cloud9 flavor
	echo "Pushing ${target}-ide image ..."
	docker tag ${source}-ide ${target}-ide
	docker push ${target}-ide
}

# ---------------------------- #

# Possible docker image tags
IMAGE_TAG_EDGE="edge-php${VERSION}"
IMAGE_TAG_STABLE="php${VERSION}"

# Read the split parts
IFS='.' read -a ver_arr <<< "$TRAVIS_TAG"

# Major version, e.g. 2-php7.2
IMAGE_TAG_RELEASE_MAJOR="${ver_arr[0]#v*}-php${VERSION}"

# Major-minor version, e.g. 2.5-php7.2
IMAGE_TAG_RELEASE_MAJOR_MINOR="${ver_arr[0]#v*}.${ver_arr[1]}-php${VERSION}"
IMAGE_TAG_LATEST="latest"

# Skip pull request builds
is_pr && exit

docker login -u "${DOCKER_USER}" -p "${DOCKER_PASS}"

# Push images
if is_edge; then
	tag_and_push ${REPO}:build-${VERSION} ${REPO}:${IMAGE_TAG_EDGE} # Example tag: edge-php7.3
elif is_stable; then
	tag_and_push ${REPO}:build-${VERSION} ${REPO}:${IMAGE_TAG_STABLE} # Example tag: php7.3
elif is_release; then
	# Have stable, major, minor tags match
	tag_and_push ${REPO}:build-${VERSION} ${REPO}:${IMAGE_TAG_STABLE} # Example tag: php7.3
	tag_and_push ${REPO}:build-${VERSION} ${REPO}:${IMAGE_TAG_RELEASE_MAJOR}  # Example tag: 2-php7.3
	tag_and_push ${REPO}:build-${VERSION} ${REPO}:${IMAGE_TAG_RELEASE_MAJOR_MINOR}  # Example tag: 2.7-php7.3
else
	# Exit if not on develop, master or release tag
	exit
fi

# Special case for the "latest" tag
# Push (base image only) on stable and release builds
if is_latest && (is_stable || is_release); then
	echo "Pushing ${REPO}:${IMAGE_TAG_LATEST} image ..."
	docker tag ${REPO}:build-${VERSION} ${REPO}:${IMAGE_TAG_LATEST}
	docker push ${REPO}:${IMAGE_TAG_LATEST}
fi
