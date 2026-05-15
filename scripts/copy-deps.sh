#!/bin/bash

# 매개변수 개수 확인
if [ "$#" -ne 5 ]; then
  echo "How to use: $0 [os_name] [target_dir] [exec_path(no ext)] [yes|no]"
  exit 1
fi

OS="$1"
TARGET_DIR="$2"
EXEC_PATH="$3"
DEL_SHARED="$4"
PREFIX="$5"

if [ "$OS" == "Windows" ]; then
  PROGRAM="$EXEC_PATH.exe"
  if [ "$DEL_SHARED" == "yes" ]; then
    rm -vrf "$TARGET_DIR"/*.dll
  fi
  LIBS=$(ldd "$PROGRAM" | grep "=> $PREFIX" | awk '{print $3}')
elif [ "$OS" == "Linux" ]; then
  PROGRAM="$EXEC_PATH"
  if [ "$DEL_SHARED" == "yes" ]; then
    rm -vrf "$TARGET_DIR"/*.so
  fi

  # 번들 불가 라이브러리 목록 (시스템/커널, GPU 드라이버 종속)
  EXCLUDE_LIBS=(
    # 시스템/커널
    "linux-vdso" "ld-linux" "ld-musl"
    "libc\.so" "libm\.so" "libpthread\.so" "libdl\.so" "librt\.so"
    "libresolv\.so" "libnss_" "libutil\.so" "libcrypt\.so" "libmvec\.so"
    # GPU/디스플레이 (호스트 드라이버 종속)
    "libGL\." "libGLX\." "libEGL\." "libOpenGL\." "libGLdispatch\." "libvulkan\."
    "libGLESv" "libgbm\." "libdrm" "libnvidia" "libcuda" "libva" "libvdpau"
    "libX11" "libxcb" "libXext" "libXrender" "libXrandr" "libXi\."
    "libXcursor" "libXfixes" "libXdamage" "libXcomposite" "libXinerama"
    "libXtst" "libSM\." "libICE\." "libxkbcommon" "libwayland"
    # 시스템 서비스
    "libdbus-1" "libsystemd" "libudev"
    # 오디오
    "libasound\." "libpulse" "libpipewire" "libjack"
    # 보안/암호화
    "libssl\." "libcrypto\." "libgnutls"
    "libpam\." "libcap"
    # 폰트
    "libfontconfig" "libfreetype"
  )
  EXCLUDE_PATTERN=$(IFS="|"; echo "${EXCLUDE_LIBS[*]}")

  LIBS=$(ldd "$PROGRAM" | grep "=> $PREFIX" | awk '{print $3}' | grep -Ev "$EXCLUDE_PATTERN")
else
  echo "Invalid OS"
  exit 1
fi

echo "Delete all Shared library files in $TARGET_DIR"

if [ ! -d "$TARGET_DIR" ]; then
  mkdir -p "$TARGET_DIR"
fi

for LIB in $LIBS; do
  cp -v "$LIB" "$TARGET_DIR"
done

if [ "$OS" == "Linux" ]; then
  if ! command -v patchelf >/dev/null 2>&1; then
    echo "WARNING: patchelf not found. Copied libraries may have hardcoded RPATHs."
  else
    for LIB in $LIBS; do
      DEST="$TARGET_DIR/$(basename "$LIB")"
      patchelf --force-rpath --set-rpath '$ORIGIN' "$DEST"
    done
    echo "RPATH patched to \$ORIGIN for all copied libraries."
  fi
fi

# if [ "$OS" == "Windows" ]; then
#   EXTRA_PATH="/ucrt64/share/qt6/plugins/platforms"
#   EXTRA_LIBS=("qdirect2d.dll" "qminimal.dll" "qoffscreen.dll" "qwindows.dll")
#   EXTRA_DEST_PATH="$TARGET_DIR/platforms"

#   mkdir -p "$EXTRA_DEST_PATH"

#   for EXTRA_LIB in ${EXTRA_LIBS[@]}; do
#     cp -v "$EXTRA_PATH/$EXTRA_LIB" "$EXTRA_DEST_PATH"
#   done
# fi

echo "All libraries copied to $TARGET_DIR"
