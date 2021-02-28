IMAGE_REPO ?=4lane-legit
IMAGE_NAME ?= tailhook

# Github host to use for checking the source tree;
# Override this variable ue with your own value if you're working on forked repo.
GIT_HOST ?= github.com/4lane-legit

PWD := $(shell pwd)
BASE_DIR := $(shell basename $(PWD))

# Keep an existing GOPATH, make a private one if it is undefined
GOPATH_DEFAULT := $(PWD)/.go
export GOPATH ?= $(GOPATH_DEFAULT)
TESTARGS_DEFAULT := "-v"
export TESTARGS ?= $(TESTARGS_DEFAULT)
DEST := $(GOPATH)/src/$(GIT_HOST)/$(BASE_DIR)
IMAGE_TAG ?= $(shell date +v%Y%m%d)-$(shell git describe --match=$(git rev-parse --short=8 HEAD) --tags --always --dirty)


LOCAL_OS := $(shell uname)
ifeq ($(LOCAL_OS),Linux)
    TARGET_OS ?= linux
    XARGS_FLAGS="-r"
else ifeq ($(LOCAL_OS),Darwin)
    TARGET_OS ?= darwin
    XARGS_FLAGS=
else
    $(error "This system's OS $(LOCAL_OS) isn't recognized/supported")
endif

all: fmt lint test build image

ifeq (,$(wildcard go.mod))
ifneq ("$(realpath $(DEST))", "$(realpath $(PWD))")
    $(error Please run 'make' from $(DEST). Current directory is $(PWD))
endif
endif

############################################################
# format section
############################################################

fmt:
	@echo "Run go fmt..."

############################################################
# lint section
############################################################

lint:
	@echo "Runing the golangci-lint..."

############################################################
# test section
############################################################

test:
	@echo "Running the tests for $(IMAGE_NAME)..."
	@go test $(TESTARGS) ./...

############################################################
# build section
############################################################

build:
	@echo "Building the $(IMAGE_NAME) binary..."
	@CGO_ENABLED=0 go build -o build/_output/bin/$(IMAGE_NAME) ./cmd/

build-linux:
	@echo "Building the $(IMAGE_NAME) binary for Docker (linux)..."
	@GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o build/_output/linux/bin/$(IMAGE_NAME) ./cmd/

############################################################
# image section
############################################################

image: build-image push-image

build-image: build-linux
	@echo "Building the docker image: $(IMAGE_REPO)/$(IMAGE_NAME):latest"
	@docker build -t $(IMAGE_REPO)/$(IMAGE_NAME):latest -f build/Dockerfile .

push-image: build-image
	@echo "Pushing the docker image for $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) and $(IMAGE_REPO)/$(IMAGE_NAME):latest..."
	@docker tag $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) $(IMAGE_REPO)/$(IMAGE_NAME):latest
	@docker push $(IMAGE_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	@docker push $(IMAGE_REPO)/$(IMAGE_NAME):latest

############################################################
# clean section
############################################################
clean:
	@rm -rf build/_output

############################################################
# Generate CSR and patch CA bundle
############################################################
create-signed-cert:
	@echo "Generate certificate bundle and CSR request for k8s admission control"
	@./scripts/webhook-create-signed-cert.sh --service sidecar-injector-webhook-svc  --secret sidecar-injector-webhook-certs --namespace sidecar-injector

patch-ca:
	cat deploy/mutatingwebhook.yaml | deploy/webhook-patch-ca-bundle.sh > helm/mutatingwebhook-ca-bundle.yaml

.PHONY: all fmt lint check test build image clean
