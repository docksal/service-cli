-include env_make

VERSION ?= php-fpm-7.2

REPO = docksal/cli
NAME = docksal-cli-7.2

.PHONY: build test push shell run start stop logs clean release

build:
	fin docker build -t $(REPO):$(VERSION) .

test:
	IMAGE=$(REPO):$(VERSION) NAME=$(NAME) ../tests/test-7.2.bats

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
	-fin docker rm -f $(NAME)

release: build
	make push -e VERSION=$(VERSION)

default: build
