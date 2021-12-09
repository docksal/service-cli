-include ../tests/env_make
-include env_make

IMAGE ?= docksal/cli
VERSION_PREFIX ?= php
VERSION ?= 7.3
BUILD_IMAGE_TAG ?= $(IMAGE):$(VERSION_PREFIX)$(VERSION)-build
NAME = docksal-cli-$(VERSION)-$(GIT_SHA7)
CWD = $(shell pwd)

# Improve write performance for /home/docker by turning it into a volume
VOLUMES = -v /home/docker

.EXPORT_ALL_VARIABLES:

.PHONY: build exec test push shell run start stop logs clean release

default: build

build:
	docker build -t $(BUILD_IMAGE_TAG) .

# See https://docs.docker.com/buildx/working-with-buildx/
# See https://github.com/docker/buildx
buildx:
	docker buildx build --tag $(BUILD_IMAGE_TAG) .
buildx-with-cache:
	docker buildx build --cache-from=type=registry,ref=$(BUILD_IMAGE_TAG) --cache-to=type=inline --tag=$(BUILD_IMAGE_TAG) .

test:
	NAME=$(NAME) VERSION=$(VERSION) ../tests/test.bats

push:
	docker push $(BUILD_IMAGE_TAG)

run: clean
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(BUILD_IMAGE_TAG)

# Copy files into container instead of mounting from the host at runtime.
# This allows running tests on a remote docker instance.
start: clean
	docker create --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(BUILD_IMAGE_TAG)
	docker cp ../tests/. $(NAME):/var/www/
	docker start $(NAME)

# Only copy docroot (not config overrides)
start-bare: clean
	docker create --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(BUILD_IMAGE_TAG)
	docker cp ../tests/docroot/. $(NAME):/var/www/docroot/
	docker start $(NAME)

# Non-interactive and non-tty docker exec (uses LF instead of CRLF line endings)
exec:
	@docker exec -u docker $(NAME) bash -lc "$(CMD)"

# Interactive docker exec
exec-it:
	@docker exec -u docker -it $(NAME) bash -ilc "$(CMD)"

shell:
	@docker exec -u docker -it $(NAME) bash -il

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

logs-follow:
	docker logs -f $(NAME)

clean:
	docker rm -vf $(NAME) >/dev/null 2>&1 || true

tags:
	@../.github/scripts/docker-tags.sh
