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
}

# ---------------------------- #

# Possible docker image tags
IMAGE_TAG_EDGE="edge${APPENDIX:+-${APPENDIX}}"
IMAGE_TAG_STABLE="stable${APPENDIX:+-${APPENDIX}}"

# Read the split parts
IFS='.' read -a ver_arr <<< "$TRAVIS_TAG"

# Major version, e.g. 2[-APPENDIX]
# APPENDIX may be php version php7.3 for example
IMAGE_TAG_RELEASE_MAJOR="${ver_arr[0]#v*}${APPENDIX:+-${APPENDIX}}"

# Major-minor version, e.g. 2.7[-APPENDIX]
IMAGE_TAG_RELEASE_MAJOR_MINOR="${ver_arr[0]#v*}.${ver_arr[1]}${APPENDIX:+-${APPENDIX}}"
IMAGE_TAG_LATEST="latest"

# Skip pull request builds
is_pr && exit

docker login -u "${DOCKER_USER}" -p "${DOCKER_PASS}"

# Push images
if is_edge; then
	tag_and_push ${REPO}:${TAG} ${REPO}:${IMAGE_TAG_EDGE} # Example tag: edge[-APPENDIX]
elif is_stable; then
	tag_and_push ${REPO}:${TAG} ${REPO}:${IMAGE_TAG_STABLE} # Example tag: stable[-APPENDIX]
elif is_release; then
	# Have stable, major, minor tags match
	tag_and_push ${REPO}:${TAG} ${REPO}:${IMAGE_TAG_STABLE} # Example tag: stable[-APPENDIX]
	tag_and_push ${REPO}:${TAG} ${REPO}:${IMAGE_TAG_RELEASE_MAJOR}  # Example tag: 2[-APPENDIX]
	tag_and_push ${REPO}:${TAG} ${REPO}:${IMAGE_TAG_RELEASE_MAJOR_MINOR}  # Example tag: 2.7[-APPENDIX]
else
	# Exit if not on develop, master or release tag
	exit
fi

# Special case for the "latest" tag
# Push (base image only) on stable and release builds
if is_latest && (is_stable || is_release); then
	tag_and_push ${REPO}:${TAG} ${REPO}:${IMAGE_TAG_LATEST}
fi
