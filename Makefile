.PHONY: testall buildall fullsuitetest

fullsuitetest: buildall testall

buildall: base_buildimage mirror_buildimage multiver_buildimage multiver_config_buildimage multiver_nodirect_buildimage

testall: base_init mirror_init multiver_init multiver_config_init multiver_nodirect_init

################
## Sample App ##
################

plan:
	terraform -chdir=./app  plan

apply:
	terraform -chdir=./app  apply -auto-approve

destroy:
	terraform -chdir=./app  destroy -auto-approve

init:
	-rm -rf ./app/terraform.d ./app/.terraform ./app/.terraform.lock.hcl ./app/.terraform.tfstate.lock.info ./app/terraform.tfstate
	terraform -chdir=./app init


#################
## Build Image ##
#################

BUILD_IMAGE_VERSION := 1.0.0

BUILD_CONTAINER_NAME := mybuildcontainer

BUILD_IMAGE_NAME_BASE := mybuildimage_base
BUILD_IMAGE_NAME_MIRROR := mybuildimage_mirror
BUILD_IMAGE_NAME_MULTIVER := mybuildimage_multiversion_mirror
BUILD_IMAGE_NAME_MULTIVER_CONFIG := mybuildimage_multiversion_config_mirror
BUILD_IMAGE_NAME_MULTIVER_NODIRECT := mybuildimage_multiversion_nodirect_mirror


.PHONY: base_buildimage base_run base_init

base_buildimage:
	docker build \
		--progress plain \
		--tag "$(BUILD_IMAGE_NAME_BASE):$(BUILD_IMAGE_VERSION)" \
		--tag "$(BUILD_IMAGE_NAME_BASE):latest" \
		--build-arg BUILD_IMAGE_VERSION="$(BUILD_IMAGE_VERSION)" \
		--file ./buildimage/Dockerfile_Base \
		./buildimage

base_run: force-stop base_buildimage
	docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_BASE)" \
		bash

base_init: force-stop
	docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_BASE)" \
		make init

.PHONY: mirror_buildimage mirror_run mirror_init

mirror_buildimage:
	docker build \
		--progress plain \
		--tag "$(BUILD_IMAGE_NAME_MIRROR):$(BUILD_IMAGE_VERSION)" \
		--tag "$(BUILD_IMAGE_NAME_MIRROR):latest" \
		--build-arg BUILD_IMAGE_VERSION="$(BUILD_IMAGE_VERSION)" \
		--file ./buildimage/Dockerfile_Mirror \
		./buildimage

mirror_run: force-stop mirror_buildimage
	docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_MIRROR)" \
		bash

mirror_init: force-stop
	docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_MIRROR)" \
		make init

.PHONY: multiver_buildimage multiver_run multiver_init

multiver_buildimage:
	docker build \
		--progress plain \
		--tag "$(BUILD_IMAGE_NAME_MULTIVER):$(BUILD_IMAGE_VERSION)" \
		--tag "$(BUILD_IMAGE_NAME_MULTIVER):latest" \
		--build-arg BUILD_IMAGE_VERSION="$(BUILD_IMAGE_VERSION)" \
		--file ./buildimage/Dockerfile_MultiVer \
		./buildimage

multiver_run: force-stop multiver_buildimage
	docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_MULTIVER)" \
		bash

multiver_init: force-stop
	docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_MULTIVER)" \
		make init

.PHONY: multiver_config_buildimage multiver_config_run multiver_config_init

multiver_config_buildimage:
	docker build \
		--progress plain \
		--tag "$(BUILD_IMAGE_NAME_MULTIVER_CONFIG):$(BUILD_IMAGE_VERSION)" \
		--tag "$(BUILD_IMAGE_NAME_MULTIVER_CONFIG):latest" \
		--build-arg BUILD_IMAGE_VERSION="$(BUILD_IMAGE_VERSION)" \
		--file ./buildimage/Dockerfile_MultiVer_Config \
		./buildimage

multiver_config_run: force-stop multiver_config_buildimage
	docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_MULTIVER_CONFIG)" \
		bash

multiver_config_init: force-stop
	docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_MULTIVER_CONFIG)" \
		make init

.PHONY: multiver_nodirect_buildimage multiver_nodirect_run multiver_nodirect_init

multiver_nodirect_buildimage:
	docker build \
		--progress plain \
		--tag "$(BUILD_IMAGE_NAME_MULTIVER_NODIRECT):$(BUILD_IMAGE_VERSION)" \
		--tag "$(BUILD_IMAGE_NAME_MULTIVER_NODIRECT):latest" \
		--build-arg BUILD_IMAGE_VERSION="$(BUILD_IMAGE_VERSION)" \
		--file ./buildimage/Dockerfile_MultiVer_NoDirect \
		./buildimage

multiver_nodirect_run: force-stop multiver_nodirect_buildimage
	docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_MULTIVER_NODIRECT)" \
		bash

multiver_nodirect_init: force-stop
	@echo "This configuration is expected to generate an error, which is ignored"
	-docker run --rm -ti \
		--name "$(BUILD_CONTAINER_NAME)" \
		--volume $$(pwd):/root/src \
		--workdir /root/src \
		"$(BUILD_IMAGE_NAME_MULTIVER_NODIRECT)" \
		make init

.PHONY: force-stop

force-stop:
	@echo "Attempting to stop running local container, if not shutdown properly."
	@echo "Normally this will generate an error, which is ignored"
	-docker stop "$(BUILD_CONTAINER_NAME)"

## Cleanup Docker
.PHONY: cleanup

cleanup:
	docker container prune -f
	docker image prune --all -f
	docker volume prune -f
	docker network prune -f
	docker builder prune --all -f