# https://www.gnu.org/software/make/manual/html_node/Makefile-Conventions.html

SHELL = /bin/bash

.SUFFIXES:

CWD=$(shell pwd)

PYTHON_VER=$(shell python --version | grep -o -E '[0-9]+[.][0-9]+')
PY_VER=$(shell echo "py$(PYTHON_VER)" | sed -e 's/\.//g')

IMAGE = google-s2-lambda

.PHONY: docker-lambda-libs
docker-lambda-libs:
	docker run --rm \
		-v $(CWD)/:/var/task:ro,delegated \
		lambci/lambda:python$(PYTHON_VER) \
		lambda_versions.lambda_handler

.PHONY: docker-lambda-shell
docker-lambda-shell:
	# docker run -it --rm lambci/lambda:build-python3.7 /bin/bash
	docker run -it --rm --entrypoint /bin/bash lambci/lambda:python$(PYTHON_VER)

.PHONY: build
build:
	docker build -t $(IMAGE) --build-arg python_ver=$(PYTHON_VER) .

.PHONY: extract
extract: build
	docker run -d --name s2-lambda $(IMAGE) /bin/sleep 5
	docker cp s2-lambda:/tmp/$(PY_VER)_google_s2.zip .
	#docker stop s2-lambda
	docker rm -f s2-lambda

.PHONY: shell
shell: build
	docker run -it --rm $(IMAGE) /bin/bash

# Auto-clean is disabled by leaving the value empty
AUTOCLEAN ?=

.PHONY: clean
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

