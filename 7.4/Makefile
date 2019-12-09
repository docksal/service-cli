-include ../tests/env_make
-include env_make

VERSION ?= 7.4
TAG_APPENDIX ?= -php$(VERSION)
BUILD_TAG = build-$(TAG_APPENDIX)
REPO = docksal/cli
NAME = docksal-cli-$(VERSION)
CWD = $(shell pwd)

# Improve write performance for /home/docker by turning it into a volume
VOLUMES += -v /home/docker

.EXPORT_ALL_VARIABLES:

.PHONY: build test push shell run start stop logs clean release

build:
	docker build --cache-from=$(REPO):edge$(TAG_APPENDIX) -t $(REPO):$(BUILD_TAG) .

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

release:
	@../scripts/docker-push.sh

default: build
