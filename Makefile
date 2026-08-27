# This Makefile is for building an AppImage for Legacy Launcher on Linux systems.

# Copyright (C) 2026 imngkhang
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.fsf.org/licenses/>.

# Here we will check the arch of the system
UNAME_M := $(shell uname -m)

# Set the default arch
ifeq ($(UNAME_M),x86_64)
    DEFAULT_ARCH := x86_64
else
    $(error Unsupported architecture: $(UNAME_M). Only x86_64 and aarch64 are supported)
endif

# make targets
.PHONY: all clean depends help

# Build for x86_64
all:
	@chmod +x buildscripts/tl_builder.sh
	@./buildscripts/tl_builder.sh

# Check dependencies
depends:
	@for cmd in jq wget curl grep sha256sum stat; do \
		if ! command -v $$cmd >/dev/null 2>&1; then \
			echo "Missing: $$cmd"; \
		else \
			echo "OK: $$cmd"; \
		fi \
	done

# Clean up build artifacts
clean:
	@echo "Cleaning up build artifacts..."
	@rm -rf dist/ *AppDir/ uruntime2appimage *.jar *RunDir/ *overlayfs*/ runimage appinfo* get-debloated-pkgs.*
	@echo "Done!"

# Show help message
help:
	@echo "Build Commands:"
	@echo "  make           - Build a x86_64 AppImage"
	@echo "  make clean     - Remove build and temporary files"
	@echo "  make depends   - Check dependencies for building"
	@echo "  make help      - Show this help and exit"
