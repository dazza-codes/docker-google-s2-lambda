# https://www.gnu.org/software/make/manual/html_node/Makefile-Conventions.html

SHELL = /bin/bash

.SUFFIXES:

IMAGE = google-s2-lambda

build:
	docker build -t $(IMAGE) .

extract: build
	docker run -d --name s2-lambda $(IMAGE) /bin/sleep 5
	docker cp s2-lambda:/tmp/py36_google_s2.zip .
	#docker stop s2-lambda
	docker rm -f s2-lambda

# Auto-clean is disabled by leaving the value empty
AUTOCLEAN ?= 

clean:
	@IMAGES=$$(docker images | grep '$(IMAGE)' | awk '{print $$1 ":" $$2}')
	@if test -n "$${IMAGES}"; then \
		if test -n "$(AUTOCLEAN)"; then \
			docker rmi -f "$${IMAGES}" 2> /dev/null || true; \
			docker system prune -f; \
		else \
			echo "$${IMAGES}" | xargs -n1 -p -r docker rmi; \
			docker system prune; \
		fi; \
	fi

.PHONY: build clean
