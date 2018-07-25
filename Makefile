-include env_make

VERSION ?= 0.12.0

REPO = czietlow/predictionio
NAME = predictionio

.PHONY: build test push shell run start stop logs clean release

container:
	fin docker container ls

build:
	fin docker build -t $(REPO):$(VERSION) .

fresh-build:
	fin docker build --no-cache -t $(REPO):$(VERSION) .

test:
	IMAGE=$(REPO):$(VERSION) NAME=$(NAME) tests/$(VERSION).bats

push:
	fin docker push $(REPO):$(VERSION)

shell: clean
	fin docker run --rm -it -p 8000:8000 -p 9200:9200 -p 9300:9300 czietlow/predictionio:0.12.0 /bin/bash
#	fin docker run --rm --name $(NAME) -it $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(VERSION) /bin/bash

exec:
	fin docker exec $(NAME) $(COMMAND)

run: clean
	fin docker run --rm --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(VERSION)

start: clean
	fin docker run -d --name $(NAME) $(PORTS) $(VOLUMES) $(ENV) $(REPO):$(VERSION) top -b

stop:
	fin docker stop $(NAME)

logs:
	fin docker logs $(NAME)

clean:
	fin docker rm -f $(NAME) || true

release: build
	make push -e VERSION=$(VERSION)

default: build
