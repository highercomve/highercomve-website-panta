CONTAINER_NAME ?= website
CONTAINER_VERSION ?= ARM32V6
EXPORT_PATH := $(shell mktemp -t $(CONTAINER_NAME).$(CONTAINER_VERSION).tgz)
EXPORT_SQUASH_PATH := "$(CURDIR)/panta/$(CONTAINER_NAME).squashfs"
EXPORT_RAW_DIR := $(shell mktemp -d -t $(CONTAINER_NAME).$(CONTAINER_VERSION).raw)

ifeq ($(DEBUG),)
QUIET = @
endif

update:
	rm -rf dist; git clone git@github.com:highercomve/highercomve.github.io.git dist;

build: update
	docker build -f Dockerfile.$(CONTAINER_VERSION) --no-cache -t $(CONTAINER_NAME):$(CONTAINER_VERSION) .

export: build
	$(QUIET)docker rm -f $(CONTAINER_NAME) || true; did=`docker run --name $(CONTAINER_NAME) -t -d -p 80:80 $(CONTAINER_NAME):$(CONTAINER_VERSION)`; docker export $$did -o $(EXPORT_PATH)
	$(QUIET)echo "Exported available at: $(EXPORT_PATH)"

panta: export
	mkdir panta; rm -rf $(EXPORT_RAW_DIR); rm -rf $(EXPORT_SQUASH_PATH); mkdir -p $(EXPORT_RAW_DIR)
	fakeroot tar -C $(EXPORT_RAW_DIR) -xf $(EXPORT_PATH)
	mksquashfs $(EXPORT_RAW_DIR) $(EXPORT_SQUASH_PATH) -comp xz
	rm -rf ${EXPORT_PATH}; rm -rf ${EXPORT_RAW_DIR}
	$(QUIET)echo "Exported available at: $(EXPORT_SQUASH_PATH)"

clean:
	rm -fr tmp/
	rm -rf dist/
