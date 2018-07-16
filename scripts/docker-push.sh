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
IMAGE_TAG_RELEASE="${TRAVIS_TAG:1:3}-php${VERSION}"
IMAGE_TAG_LATEST="latest"

# Skip pull request builds
is_pr && exit

# Figure out which docker image tag to use
if is_edge; then
	IMAGE_TAG=${IMAGE_TAG_EDGE}
elif is_stable; then
	IMAGE_TAG=${IMAGE_TAG_STABLE}
elif is_release; then
	IMAGE_TAG=${IMAGE_TAG_RELEASE}
else
	# Exit if not on develop, master or release tag
	exit
fi

docker login -u "${DOCKER_USER}" -p "${DOCKER_PASS}"

# Push images
tag_and_push ${REPO}:build-${VERSION} ${REPO}:${IMAGE_TAG}

# Special case for the "latest" tag
# Push (base image only) on stable and release builds
if is_latest && (is_stable || is_release); then
	echo "Pushing ${REPO}:${IMAGE_TAG_LATEST} image ..."
	docker tag ${REPO}:build-${VERSION} ${REPO}:${IMAGE_TAG_LATEST}
	docker push ${REPO}:${IMAGE_TAG_LATEST}
fi
