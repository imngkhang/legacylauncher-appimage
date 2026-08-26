#!/bin/bash
set -euo pipefail

MANIFEST_OUTPUT="manifest.yaml"
export ARCH="x86_64"
export APP_NAME="LegacyLauncher"
export DESKTOP="legacylauncher.desktop"
export ICON="legacylauncher.png"
export STARTUPWMCLASS="ru-turikhay-tlauncher-bootstrap-Bootstrap"
export UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*-$ARCH.AppImage.zsync"
export SHA256=$(grep -A 5 "x86_64:" "$MANIFEST_OUTPUT" | grep "sha256:" | sed -E 's/.*sha256:[[:space:]]*"([^"]*)".*/\1/')
export SIZE=$(grep -A 5 "x86_64:" "$MANIFEST_OUTPUT" | grep "size:" | sed -E 's/.*size:[[:space:]]*//' | tr -d '"'\''')

DIST_DIR="dist"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"

echo "=== Đang bắt đầu build RunImage cho ${APP_NAME} (${ARCH}) ==="

if [[ ! -f "legacylauncher" ]] || [[ ! -f "legacylauncher.desktop" ]]; then
  echo "Lỗi: Cần có file 'legacylauncher' và 'legacylauncher.desktop' ở thư mục hiện tại!" >&2
  exit 1
fi

if [ ! -x 'runimage' ]; then
	echo '== Tải base RunImage...'
	wget -q -O runimage "https://github.com/VHSgunzo/runimage/releases/download/continuous/runimage-$(uname -m)"
	chmod +x runimage
fi

run_install() {
	set -e

	INSTALL_PKGS=(
		jre21-openjdk wget mesa vulkan-radeon lib32-vulkan-radeon
		vulkan-intel lib32-vulkan-intel vulkan-nouveau lib32-vulkan-nouveau
		libpulse lib32-libpulse
	)

  rim-update
	pac --needed --noconfirm -S "${INSTALL_PKGS[@]}"

  EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"
	wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
	chmod +x ./get-debloated-pkgs.sh
	./get-debloated-pkgs.sh --add-mesa llvm-libs gtk3-mini opus-mini libxml2-mini gdk-pixbuf2-mini librsvg-mini icu-mini


	mkdir -p /usr/lib/legacy_launcher
	TMP_JAR=$(mktemp)
    BOOTSTRAP_SUCCESS=false

    for host in llaun.ch eu1.llaun.ch lln4.ru ru1.lln4.ru; do
        echo "Attempting to download from $host..."
    
        # Tải file về file tạm thay vì đè trực tiếp lên file hệ thống
        if wget --timeout=15 --tries=2 "https://$host/jar" -O "$TMP_JAR"; then
            DOWNLOADED_SIZE=$(stat -c%s "$TMP_JAR")
			DOWNLOADED_SHA256=$(sha256sum "$TMP_JAR" | awk '{print $1}')
            if [[ "$DOWNLOADED_SHA256" != "$SHA256" ]]; then
                echo "Warning: SHA256 checksum failed from $host. Skipping..."
                exit 1
            fi
			if [[ "$DOWNLOADED_SIZE" != "$SIZE" ]]; then
                echo "Warning: Size mismatch from $host (Got: $DOWNLOADED_SIZE, Expected: $SIZE). Skipping..."
                exit 1
            fi

        # 3. Nếu vượt qua cả 2 bài test, sao chép vào vị trí chính thức
        mkdir -p /usr/lib/legacy_launcher
        mv "$TMP_JAR" /usr/lib/legacy_launcher/bootstrap.jar
        BOOTSTRAP_SUCCESS=true
        echo "Successfully downloaded and verified bootstrap.jar from $host!"
        break
    fi
done

# Dọn dẹp file tạm nếu vòng lặp thất bại ở mọi host
rm -f "$TMP_JAR"
	[[ "$BOOTSTRAP_SUCCESS" = false ]] && { echo "Lỗi tải bootstrap jar!"; exit 1; }


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

	rim-shrink --all
	rim-build -s legacylauncher.RunImage
}
export -f run_install

RIM_OVERFS_MODE=1 RIM_NO_NVIDIA_CHECK=1 ./runimage bash -c run_install
./legacylauncher.RunImage --runtime-extract
rm -f ./legacylauncher.RunImage

mv ./RunDir ./AppDir
mv ./AppDir/Run ./AppDir/AppRun

cp legacylauncher ./AppDir/rootfs/usr/bin/legacylauncher
cp legacylauncher.png ./AppDir/rootfs/usr/share/icons/hicolor/128x128/
cp legacylauncher.desktop ./AppDir/rootfs/usr/share/applications/legacylauncher.desktop

chmod +x ./AppDir/rootfs/usr/bin/legacylauncher


mkdir -p "$DIST_DIR"
echo "==> Đang khởi tạo AppImage với uruntime..."
export VERSION="$(grep -A 5 "x86_64:" "$MANIFEST_OUTPUT" | grep "version:" | sed -E 's/.*version:[[:space:]]*"([^"]*)".*/\1/')"
export OUTNAME=LegacyLauncher-Bootstrap-v"$VERSION"-anylinux-"$ARCH".AppImage
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage

export ADD_PERMA_ENV_VARS='RIM_ALLOW_ROOT=1'
./uruntime2appimage

mv ./*.AppImage "${DIST_DIR}/" 2>/dev/null || true
mv ./*.AppImage.zsync "${DIST_DIR}/" 2>/dev/null || true
rm -rf "${DIST_DIR}/AppDir" 2>/dev/null
mv ./AppDir "${DIST_DIR}/" 2>/dev/null || true