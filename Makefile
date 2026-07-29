# Root Makefile — webserver-oob-demo build
#
# Usage:
#   make                           Build everything for default device (am335x)
#   make DEVICE=am62dxx            Build for am62dxx
#   make CC=aarch64-linux-gnu-gcc  Cross-compile native binaries for ARM target
#   make clean                     Remove build artifacts
#
# Deployment is handled by the Yocto Wrynos SDK image (bitbake webserver-oob).

DEVICE ?= am335x
CC     ?= gcc

export CC CFLAGS LDFLAGS

.PHONY: all build deps build-native build-frontend clean info

all: build

build: deps build-native build-frontend

deps:
	cd common/webserver && npm install

build-native:
	$(MAKE) -C common/linux_app
	@if [ -d devices/$(DEVICE)/linux_app ]; then \
	    $(MAKE) -C devices/$(DEVICE)/linux_app; \
	fi

build-frontend:
	cd frontend && npm install && npm run build

clean:
	$(MAKE) -C common/linux_app clean
	@if [ -d devices/$(DEVICE)/linux_app ]; then \
	    $(MAKE) -C devices/$(DEVICE)/linux_app clean; \
	fi


# ── Info ─────────────────────────────────────────────────────────────

info:
	@echo "Device:     $(DEVICE)"
	@echo "CC:         $(CC)"
	@echo "Device dir: $(CURDIR)/devices/$(DEVICE)"
	@echo "Demos dir:  $(CURDIR)/demos"
