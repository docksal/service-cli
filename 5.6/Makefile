-include env_make

PHP_VERSION = 5.6
VERSION ?= php-fpm-$(PHP_VERSION)

REPO = docksal/cli
NAME = docksal-cli-$(PHP_VERSION)

# Improve write performance for /home/docker by turning it into a volume
VOLUMES += -v /home/docker

.PHONY: build test push shell run start stop logs clean release

build:
	fin docker build -t $(REPO):$(VERSION) .

test:
	IMAGE=$(REPO):$(VERSION) NAME=$(NAME) PHP_VERSION=$(PHP_VERSION) ../tests/test.bats

push:
	fin docker push $(REPO):$(VERSION)

shell:
	fin docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(VERSION) /bin/bash

run:
	fin docker run --rm --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(VERSION)

start:
	fin docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(VERSION)

stop:
	fin docker stop $(NAME)

logs:
	fin docker logs $(NAME)

clean:
	fin docker rm -f $(NAME)

release: build
	make push -e VERSION=$(VERSION)

default: build
