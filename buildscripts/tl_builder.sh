#!/usr/bin/env bash

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

# This is the builder for Legacy Launcher
set -euo pipefail

MANIFEST_OUTPUT="manifest.yaml"
RAW_REPO="${GITHUB_REPOSITORY:-$(git config --get remote.origin.url | sed -E 's|.*github\.com[:/ ]||; s|\.git$||; s|/*$||')}"
REPO=$(echo "$RAW_REPO" | sed 's|\/|\||' | sed -E 's|^[^a-zA-Z0-9]+||')
export ARCH="x86_64"
export APP_NAME="LegacyLauncher"
export DESKTOP="legacylauncher.desktop"
export ICON="legacylauncher.png"
export STARTUPWMCLASS="ru-turikhay-tlauncher-bootstrap-Bootstrap"
export UPINFO="gh-releases-zsync|${REPO}|continuous|LegacyLauncher-Bootstrap-*-anylinux-"$ARCH".AppImage.zsync"
export SHA256=$(grep -A 5 "x86_64:" "$MANIFEST_OUTPUT" | grep "sha256:" | sed -E 's/.*sha256:[[:space:]]*"([^"]*)".*/\1/')
export SIZE=$(grep -A 5 "x86_64:" "$MANIFEST_OUTPUT" | grep "size:" | sed -E 's/.*size:[[:space:]]*//' | tr -d '"'\''')

DIST_DIR="dist"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

echo "=== Building AppImage for Legacy Launcher ==="

if [[ ! -f "legacylauncher" ]] || [[ ! -f "legacylauncher.desktop" ]]; then
  echo "Error: Cannot found legacylauncher and/or legacylauncher.desktop file(s)" >&2
  exit 1
fi

if [ ! -x 'runimage' ]; then
	echo '=== Downloading RunImage base...'
	wget -q -O runimage "https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-$ARCH"
	chmod +x runimage
fi

run_install() {
	set -e
    
	# This is the package we need to install
	INSTALL_PKGS=(
		jre21-openjdk wget mesa vulkan-radeon lib32-vulkan-radeon
		vulkan-intel lib32-vulkan-intel vulkan-nouveau lib32-vulkan-nouveau
		libpulse lib32-libpulse
	)
    # Update and install packages
	echo '== checking for updates'
    rim-update
	pac --needed --noconfirm -S "${INSTALL_PKGS[@]}"
    # Download debloat tool
	echo '== debloating...'
    EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"
	wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
	chmod +x ./get-debloated-pkgs.sh
	./get-debloated-pkgs.sh --add-mesa llvm-libs gtk3-mini opus-mini libxml2-mini gdk-pixbuf2-mini librsvg-mini icu-mini

    # Make the dirs and preparing for downloading the bootstrap
	mkdir -p /usr/lib/legacy_launcher
	TMP_JAR=$(mktemp)
    BOOTSTRAP_SUCCESS=false

    for host in llaun.ch eu1.llaun.ch lln4.ru ru1.lln4.ru; do
        echo "=== attempting to download from $host..."
    
        # Download the boootstrap to temp folder, and check the checksum
        if wget --timeout=15 --tries=2 "https://$host/jar" -O "$TMP_JAR"; then
            DOWNLOADED_SIZE=$(stat -c%s "$TMP_JAR")
			DOWNLOADED_SHA256=$(sha256sum "$TMP_JAR" | awk '{print $1}')
            if [[ "$DOWNLOADED_SHA256" != "$SHA256" ]]; then
                echo "=== Error: SHA256 checksum failed from $host."
                exit 1
            fi
			if [[ "$DOWNLOADED_SIZE" != "$SIZE" ]]; then
                echo "=== Error: Size mismatch from $host (Got: $DOWNLOADED_SIZE, Expected: $SIZE)."
                exit 1
            fi

        # If it success we will install the bootstrap
        mkdir -p /usr/lib/legacy_launcher
        mv "$TMP_JAR" /usr/lib/legacy_launcher/bootstrap.jar
        BOOTSTRAP_SUCCESS=true
        echo "=== successfully downloaded and verified the .jar"
        break
        fi
    done

    # Cleanup if it fails
    rm -f "$TMP_JAR"
	[[ "$BOOTSTRAP_SUCCESS" = false ]] && { echo "error when downloading bootstrap"; exit 1; }

    # Here is the core envs, to run the AppImage
	cat <<- 'EOF' > "$RUNDIR/config/Run.rcfg"
	RIM_CMPRS_LVL="${RIM_CMPRS_LVL:=22}"
	RIM_CMPRS_BSIZE="${RIM_CMPRS_BSIZE:=25}"
	RIM_HOST_XDG_OPEN="${RIM_HOST_XDG_OPEN:=1}"
	RIM_SYS_NVLIBS="${RIM_SYS_NVLIBS:=1}"
	RIM_NVIDIA_DRIVERS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/runimage_nvidia"
	RIM_SHARE_ICONS="${RIM_SHARE_ICONS:=1}"
	RIM_SHARE_FONTS="${RIM_SHARE_FONTS:=1}"
	RIM_SHARE_THEMES="${RIM_SHARE_THEMES:=1}"
	RIM_HOST_TOOLS=git,xxd,xwininfo,xdotool,wget,unzip,yad
	RIM_BIND="/usr/share/locale:/usr/share/locale,/usr/lib/locale:/usr/lib/locale${RIM_EXTRA_BIND:+,${RIM_EXTRA_BIND}}"
	RIM_COPY_RESOLVCONF=1
	RIM_WAIT_RPIDS_EXIT=1
	RIM_AUTORUN=legacylauncher
	EOF
    
	echo "=== building the RunImage..."
	rim-shrink --all
	rim-build -s legacylauncher.RunImage
}
export -f run_install

# Now we will build the RunImage

RIM_OVERFS_MODE=1 RIM_NO_NVIDIA_CHECK=1 ./runimage bash -c run_install

# Extract it
./legacylauncher.RunImage --runtime-extract
rm -f ./legacylauncher.RunImage

# Move RunDir to AppDir for wrapping it to AppImage
mv ./RunDir ./AppDir
mv ./AppDir/Run ./AppDir/AppRun

cp legacylauncher ./AppDir/rootfs/usr/bin/legacylauncher
cp legacylauncher.png ./AppDir/rootfs/usr/share/icons/hicolor/128x128/
cp legacylauncher.desktop ./AppDir/rootfs/usr/share/applications/legacylauncher.desktop

chmod +x ./AppDir/rootfs/usr/bin/legacylauncher

# Build the AppImage

mkdir -p "$DIST_DIR"
echo "=== we are now building the AppImage..."
export VERSION="$(grep -A 5 "x86_64:" "$MANIFEST_OUTPUT" | grep "version:" | sed -E 's/.*version:[[:space:]]*"([^"]*)".*/\1/')"
# Naming it bootstrap because the launcher's jar is self downloaded
export OUTNAME=LegacyLauncher-Bootstrap-v"$VERSION"-anylinux-"$ARCH".AppImage
# We will use uruntime
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage

export ADD_PERMA_ENV_VARS='RIM_ALLOW_ROOT=1'
./uruntime2appimage --make-appimage

mv ./*.AppImage "${DIST_DIR}/" 2>/dev/null || true
mv ./*.AppImage.zsync "${DIST_DIR}/" 2>/dev/null || true
rm -rf "${DIST_DIR}/AppDir" 2>/dev/null
mv ./AppDir "${DIST_DIR}/" 2>/dev/null || true