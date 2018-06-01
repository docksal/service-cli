-include env_make

VERSION ?= 5.6
REPO = docksal/cli
TAG = build-$(VERSION)
NAME = docksal-cli-$(VERSION)

# Improve write performance for /home/docker by turning it into a volume
VOLUMES += -v /home/docker

.PHONY: build test push shell run start stop logs clean release

build:
	docker build -t $(REPO):$(TAG) .

test:
	IMAGE=$(REPO):$(TAG) NAME=$(NAME) VERSION=$(VERSION) ../tests/test.bats

push:
	docker push $(REPO):$(TAG)

shell:
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG) /bin/bash

run:
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

start:
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

exec:
	docker exec -it $(NAME) /bin/bash

stop:
	docker stop $(NAME)

logs:
	docker logs $(NAME)

clean:
	docker rm -f $(NAME)

release: build
	make push -e TAG=$(TAG)

default: build
