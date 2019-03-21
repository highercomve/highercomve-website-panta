CONTAINER_NAME ?= highercomve-website-panta
CONTAINER_REPO ?= git@github.com:highercomve/highercomve-website-panta.git
CONTAINER_VERSION ?= ARM32V6
EXPORT_PATH := $(shell mktemp -t $(CONTAINER_NAME).tgz.XXXXXX)
EXPORT_SQUASH_PATH := $(shell mktemp -t $(CONTAINER_NAME).XXXXXX).squashfs
EXPORT_RAW_DIR := $(shell mktemp -d -t $(CONTAINER_NAME).raw.XXXXXX)

ifeq ($(DEBUG),)
QUIET = @
endif

build:
	git clone git@github.com:highercomve/highercomve.github.io.git dist; mkdir tmp; curl -L https://github.com/multiarch/qemu-user-static/releases/download/v2.12.0-1/qemu-arm-static > tmp/qemu-arm-static; chmod a+x tmp/qemu-arm-static
	docker build -f Dockerfile.$(CONTAINER_VERSION) --no-cache -t $(CONTAINER_NAME):$(CONTAINER_VERSION) .

export: build
	$(QUIET)docker rm -f $(CONTAINER_NAME) || true; did=`docker run --name $(CONTAINER_NAME) -t -d -p 80:80 $(CONTAINER_NAME):$(CONTAINER_VERSION)`; docker export $$did -o $(EXPORT_PATH)
	$(QUIET)echo "Exported available at: $(EXPORT_PATH)"

$(EXPORT_SQUASH_PATH): export
	rm -rf $(EXPORT_RAW_DIR); mkdir -p $(EXPORT_RAW_DIR)
	rm -rf $(EXPORT_RAW_DIR)/usr/bin/qemu-*
	fakeroot tar -C $(EXPORT_RAW_DIR) -xf $(EXPORT_PATH)
	mksquashfs $(EXPORT_RAW_DIR) $(EXPORT_SQUASH_PATH) -comp xz

export-squash: $(EXPORT_SQUASH_PATH)
	rm ${CONTAINER_NAME}.$(CONTAINER_VERSION).squashfs
	mv $(EXPORT_SQUASH_PATH) ./${CONTAINER_NAME}.$(CONTAINER_VERSION).squashfs
	rm -rf ${EXPORT_PATH}
	rm -rf ${EXPORT_SQUASH_PATH}
	rm -rf ${EXPORT_RAW_DIR}

clean:
	rm -fr tmp/
	rm -rf dist/
