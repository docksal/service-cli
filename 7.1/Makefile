-include ../tests/env_make
-include env_make

VERSION ?= 7.1
REPO = docksal/cli
TAG = build-$(VERSION)
NAME = docksal-cli-$(VERSION)
CWD = $(shell pwd)

# Improve write performance for /home/docker by turning it into a volume
VOLUMES += -v /home/docker

.PHONY: build test push shell run start stop logs clean release

build:
	docker build --cache-from=$(REPO):edge-php$(VERSION) -t $(REPO):$(TAG) .

test:
	IMAGE=$(REPO):$(TAG) NAME=$(NAME) VERSION=$(VERSION) ../tests/test.bats

push:
	docker push $(REPO):$(TAG)

run: clean
	docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

start: clean
	docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(TAG)

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

release: build
	make push -e TAG=$(TAG)

default: build
