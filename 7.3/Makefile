-include ../tests/env_make
-include env_make

VERSION ?= 7.3

SOFTWARE_VERSION ?= php$(VERSION)
BUILD_TAG = build-$(SOFTWARE_VERSION)
REPO = docksal/cli
NAME = docksal-cli-$(VERSION)
CWD = $(shell pwd)

# Improve write performance for /home/docker by turning it into a volume
VOLUMES += -v /home/docker

.EXPORT_ALL_VARIABLES:

.PHONY: build test push shell run start stop logs clean release

build:
	docker build -t $(REPO):$(BUILD_TAG) .

# See https://docs.docker.com/buildx/working-with-buildx/
# See https://github.com/docker/buildx
buildx:
	docker buildx build --tag $(REPO):$(BUILD_TAG) .
buildx-with-cache:
	docker buildx build --cache-from=type=registry,ref=ghcr.io/$(REPO):$(BUILD_TAG) --cache-to=type=inline --tag=$(REPO):$(BUILD_TAG) .

test:
	IMAGE=$(REPO):$(BUILD_TAG) NAME=$(NAME) VERSION=$(VERSION) ../tests/test.bats

push:
	docker push $(REPO):$(BUILD_TAG)

run: clean
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(BUILD_TAG)

start: clean
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(BUILD_TAG)

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

release:
	@../scripts/docker-push.sh

default: build
