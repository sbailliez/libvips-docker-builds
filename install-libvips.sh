#!/bin/bash
#
# Compile libvips and some of its needed dependencies to support jpeg,avif,webp,png and gif processing
# This has not been tested extensively, so use at your own risk.
#
# This takes ~18min to compile on a t3.small, ~10min on a m6a.large
#
# TODO cleanup the flags everywhere to be consistent
#
set -ex

# make pushd silent
pushd () {
  command pushd "$@" > /dev/null
}

# create unique tmp dir
DIR_TMP="$(mktemp -d)"

INSTALL_DIR=/usr/local

LIBDE265_VER=1.0.15
LIBHEIF_VER=1.19.5
LIBVIPS_VER=8.16.0
LIBX265_VER=4.1
LIBAOM_VER=3.8.3
LIBHWY_VER=1.2.0
LIBSPNG_VER=0.7.4
LIBCGIF_VER=0.4.1

# download and overwrite the output file if it exists
download() {
  curl -fLO $1
}

# untar an archive and deletes it
tarx() {
  tar -xf $1 && rm -f $1
}

install_dependencies() {
  # Dependencies needed to compile
  echo "Installing dependencies via dnf ..."
  dnf --quiet --assumeyes update
  dnf --quiet --assumeyes groupinstall "Development Tools"
  dnf --quiet --assumeyes install wget tar meson pkgconf-pkg-config expat-devel glib2-devel
  dnf --quiet --assumeyes install nasm yasm cmake

  # Available on al2023 and used by libvips
  dnf --quiet --assumeyes install libwebp-devel libjpeg-turbo-devel libexif-devel libtiff-devel ImageMagick-devel libimagequant-devel libarchive-devel

  # not used if highway is used ?
  dnf --quiet --assumeyes install orc-devel
  # not used if libspng is used ?
  dnf --quiet --assumeyes install libpng-devel
}

install_libspng() {
  # libspng is faster than libpng and is preferred since 8.13
  # https://www.libvips.org/2022/05/28/What's-new-in-8.13.html
  echo
  echo "Installing libspng ${LIBSPNG_VER} for libvips"
  pushd "$DIR_TMP"
  
  REMOTE_FILE="v${LIBSPNG_VER}.tar.gz"
  rm -rf libspng-${LIBSPNG_VER}
  download "https://github.com/randy408/libspng/archive/refs/tags/${REMOTE_FILE}"
  tarx ${REMOTE_FILE}
  cd libspng-${LIBSPNG_VER}
  meson build
  cd build
  ninja
  ninja install
  
  pushd "$DIR_TMP"
  rm -rf libspng-${LIBSPNG_VER}
}

install_libcgif() {
  echo
  echo "Installing cgif ${LIBCGIF_VER}"
  pushd "$DIR_TMP"
  
  REMOTE_FILE="v${LIBCGIF_VER}.tar.gz"
  rm -rf "cgif-${LIBCGIF_VER}"
  download "https://github.com/dloebl/cgif/archive/refs/tags/${REMOTE_FILE}"
  tarx ${REMOTE_FILE}
  cd "cgif-${LIBCGIF_VER}"
  meson setup build --prefix=$INSTALL_DIR --default-library=static --buildtype=release -Dexamples=false -Dtests=false
  meson install -C build
  
  pushd "$DIR_TMP"
  rm -rf "cgif-${LIBCGIF_VER}"
}

install_libhwy() {
  echo
  echo "Installing libhwy ${LIBHWY_VER} for libvips"
  pushd "$DIR_TMP"
  
  REMOTE_FILE="highway-${LIBHWY_VER}.tar.gz"
  rm -rf highway-${LIBHWY_VER}
  download "https://github.com/google/highway/releases/download/${LIBHWY_VER}/${REMOTE_FILE}"
  tarx ${REMOTE_FILE}
  cd highway-${LIBHWY_VER}
  mkdir -p build && cd build
  cmake .. -DHWY_ENABLE_TESTS:BOOL=OFF -DHWY_ENABLE_EXAMPLES:BOOL=OFF -DHWY_ENABLE_CONTRIB:BOOL=OFF -DCMAKE_INSTALL_PREFIX:PATH="$INSTALL_DIR"
  make -j $(nproc)
  make install
  
  pushd "$DIR_TMP"
  rm -rf highway-${LIBHWY_VER}
}

install_libaom() {
  echo
  echo "Installing aom ${LIBAOM_VER} for libheif"
  pushd "$DIR_TMP"

  REMOTE_FILE="v${LIBAOM_VER}.tar.gz"
  rm -rf aom && rm -rf aom_buid
  mkdir -v aom && mkdir -v aom_build && cd aom
  download "https://aomedia.googlesource.com/aom/+archive/${REMOTE_FILE}"
  tarx ${REMOTE_FILE}
  cd ../aom_build
  MINIMAL_INSTALL="-DENABLE_TESTS=0 -DENABLE_TOOLS=0 -DENABLE_EXAMPLES=0 -DENABLE_DOCS=0 -DENABLE_TESTDATA=0" cmake $MINIMAL_INSTALL -DCMAKE_INSTALL_PREFIX=$INSTALL_DIR -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_SHARED_LIBS=1 ../aom
  make -s -j $(nproc)
  make install
  
  pushd "$DIR_TMP"
  rm -rf aom && rm -rf aom_build
}

install_x265() {
  echo
  echo "Installing x265 ${LIBX265_VER} for libheif"
  pushd "$DIR_TMP"

  REMOTE_FILE="x265_${LIBX265_VER}.tar.gz"
  rm -rf x265_${LIBX265_VER}
  download "https://bitbucket.org/multicoreware/x265_git/downloads/${REMOTE_FILE}"
  tarx ${REMOTE_FILE}
  cd x265_${LIBX265_VER}/build/linux
  cmake -G "Unix Makefiles" -DENABLE_PIC=:BOOL=1 -DENABLE_SHARED:BOOL=1 -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ ../../source
  make -s -j$(nproc)
  make install

  pushd "$DIR_TMP"
  rm -rf x265_${LIBX265_VER}
}

install_libde265() {
  echo
  echo "Installing libde265 ${LIBDE265_VER} for libheif"
  pushd "$DIR_TMP"
  
  REMOTE_FILE="libde265-${LIBDE265_VER}.tar.gz"
  rm -rf libde265-*
  download "https://github.com/strukturag/libde265/releases/download/v${LIBDE265_VER}/${REMOTE_FILE}"
  tarx ${REMOTE_FILE}
  cd libde265-${LIBDE265_VER}
  mkdir build
  cd build
  cmake ..
  make -s -j $(nproc)
  make install

  pushd "$DIR_TMP"
  rm -rf libde265-*
}

install_libheif() {
  echo
  echo "Installing libheif ${LIBHEIF_VER}"
  pushd "$DIR_TMP"
  
  REMOTE_FILE="libheif-${LIBHEIF_VER}.tar.gz"
  rm -rf libheif-${LIBHEIF_VER}
  download "https://github.com/strukturag/libheif/releases/download/v${LIBHEIF_VER}/${REMOTE_FILE}"
  tarx ${REMOTE_FILE}
  cd libheif-${LIBHEIF_VER}
  mkdir build
  cd build
  cmake --preset=release ..
  make -s -j $(nproc)
  make install
  
  pushd "$DIR_TMP"
  rm -rf libheif-${LIBHEIF_VER}
}

install_libvips() {
  echo
  echo "Installing libvips ${LIBVIPS_VER} "
  pushd "$DIR_TMP"
  
  REMOTE_FILE="vips-${LIBVIPS_VER}.tar.xz"
  rm -rf vips-${LIBVIPS_VER}
  download "https://github.com/libvips/libvips/releases/download/v${LIBVIPS_VER}/${REMOTE_FILE}"
  tarx ${REMOTE_FILE}
  cd vips-${LIBVIPS_VER}
  meson setup build --prefix ${INSTALL_DIR}
  cd build
  meson compile
  meson install
  
  pushd "$DIR_TMP"
  rm -rf vips-${LIBVIPS_VER}
}

assert_al2023() {
  # check we are really on al2023 to avoid any confusion
  if [ $(grep -ic PLATFORM_ID=\"platform:al2023\" /etc/os-release) -ne 1 ]; then
    echo "Unsupported distribution. Only works on al2023."
    exit 1
  fi
}

assert_sudo() {
  # check it is being run as privileged user
  if [[ $EUID -ne 0 ]]; then
      echo "This script has to be run with superuser privileges (eg. root or sudo)" 1>&2
    exit 1
  fi
}

assert_sudo
assert_al2023
install_dependencies


cd $DIR_TMP

install_libspng
install_libcgif
install_libhwy
install_libaom
install_x265
install_libde265
install_libheif

install_libvips

# make sure libs can be loaded
echo "Updating ld.so.conf.d ..."
echo "${INSTALL_DIR}/lib64" | tee /etc/ld.so.conf.d/local-lib64.conf
echo "${INSTALL_DIR}/lib" | tee /etc/ld.so.conf.d/local-lib.conf
ldconfig

echo "Running vips $(which vips)"
vips -v && vips --vips-config

echo "Success. vips should be up and running"
