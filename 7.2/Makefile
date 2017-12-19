-include env_make

PHP_VERSION = 7.2
VERSION ?= php-fpm-$(PHP_VERSION)

REPO = docksal/cli
NAME = docksal-cli-$(PHP_VERSION)

# Improve write performance for /home/docker by turning it into a volume
VOLUMES += -v /home/docker

.PHONY: build test push shell run start stop logs clean release

build:
	docker build -t $(REPO):$(VERSION) .

test:
	IMAGE=$(REPO):$(VERSION) NAME=$(NAME) PHP_VERSION=$(PHP_VERSION) ../tests/test.bats

push:
	docker push $(REPO):$(VERSION)

shell:
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(VERSION) /bin/bash

run:
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(VERSION)

start:
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(VERSION)

exec:
	docker exec -it $(NAME) /bin/bash

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	docker rm -f $(NAME)

release: build
	make push -e VERSION=$(VERSION)

default: build
