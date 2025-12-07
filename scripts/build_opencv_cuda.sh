#!/usr/bin/env bash
set -euo pipefail

# Build OpenCV with CUDA on Ubuntu 24.04 / Linux Mint 22.2 (Ubuntu Noble base)
# Default: OpenCV 4.12.0, CUDA enabled, contrib modules, Release build.
# Requires: CUDA toolkit installed; for best results, driver >= 550 and CUDA >= 12.x.
# For RTX 4050 (Ada, SM 8.9) we set CUDA_ARCH_BIN/PTX=8.9.

OPENCV_VERSION="4.12.0"
INSTALL_PREFIX="/usr/local"
BUILD_DIR="$HOME/opencv-build"
NPROC="$(nproc)"
CUDA_ARCH="8.9"

usage() {
  cat <<EOF
Usage: $(basename "$0") [--install-deps] [--with-dnn] [--prefix /usr/local] [--opencv-version 4.12.0]

Options:
  --install-deps   Install required packages via apt (needs sudo)
  --with-dnn       Enable DNN CUDA backend (requires cuDNN; otherwise still works without cuDNN)
  --prefix PATH    CMake install prefix (default: /usr/local)
  --opencv-version VERSION  OpenCV version tag (default: 4.12.0)
EOF
}

WITH_DNN=0
INSTALL_DEPS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-deps) INSTALL_DEPS=1; shift ;;
    --with-dnn) WITH_DNN=1; shift ;;
    --prefix) INSTALL_PREFIX="$2"; shift 2 ;;
    --opencv-version) OPENCV_VERSION="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1"; usage; exit 1 ;;
  esac
done

if [[ $INSTALL_DEPS -eq 1 ]]; then
  echo "Installing build dependencies (sudo required)..."
  sudo apt update
  # Note: package names differ across Ubuntu releases; use ones valid for 24.04 (Noble)
  sudo apt install -y build-essential cmake git pkg-config \
    gcc-12 g++-12 \
    libgtk-3-dev libgtk2.0-dev \
    libavcodec-dev libavformat-dev libswscale-dev \
    libtbb-dev \
    libjpeg-dev libpng-dev libtiff-dev \
    libdc1394-dev libraw1394-dev \
    libopenexr-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev \
    python3-dev python3-numpy python3-pip \
    libeigen3-dev
fi

mkdir -p "$BUILD_DIR" && cd "$BUILD_DIR"

# Clone OpenCV sources
if [[ ! -d opencv ]]; then
  git clone https://github.com/opencv/opencv.git
fi
if [[ ! -d opencv_contrib ]]; then
  git clone https://github.com/opencv/opencv_contrib.git
fi
cd opencv && git fetch --tags && git checkout "${OPENCV_VERSION}" && cd ..
cd opencv_contrib && git fetch --tags && git checkout "${OPENCV_VERSION}" && cd ..

# Configure
rm -rf build && mkdir build && cd build

CUDNN_FLAG="-DWITH_CUDNN=OFF"
DNN_FLAG="-DBUILD_opencv_dnn=ON"
DNN_CUDA_FLAG="-DOPENCV_DNN_CUDA=OFF"
if [[ $WITH_DNN -eq 1 ]]; then
  CUDNN_FLAG="-DWITH_CUDNN=ON"
  DNN_CUDA_FLAG="-DOPENCV_DNN_CUDA=ON"
fi

cmake ../opencv \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=/usr/bin/gcc-12 \
  -DCMAKE_CXX_COMPILER=/usr/bin/g++-12 \
  -DCMAKE_INSTALL_PREFIX="${INSTALL_PREFIX}" \
  -DOPENCV_GENERATE_PKGCONFIG=ON \
  -DOPENCV_ENABLE_NONFREE=ON \
  -DWITH_CUDA=ON \
  -DCMAKE_CUDA_HOST_COMPILER=/usr/bin/g++-12 \
  -DCUDA_ARCH_BIN="${CUDA_ARCH}" \
  -DCUDA_ARCH_PTX="${CUDA_ARCH}" \
  -DENABLE_FAST_MATH=ON \
  -DCUDA_FAST_MATH=ON \
  -DWITH_CUBLAS=ON \
  -DEigen3_DIR=/usr/lib/cmake/eigen3 \
  -DEIGEN_INCLUDE_PATH=/usr/include/eigen3 \
  ${CUDNN_FLAG} ${DNN_FLAG} ${DNN_CUDA_FLAG} \
  -DWITH_GSTREAMER=ON \
  -DWITH_OPENGL=ON \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTS=OFF \
  -DBUILD_PERF_TESTS=OFF \
  -DOPENCV_EXTRA_MODULES_PATH="${BUILD_DIR}/opencv_contrib/modules"

# Build
make -j"${NPROC}"

echo
echo "Build finished. To install system-wide, run:"
echo "  sudo make install && sudo ldconfig"
echo

# Post-install hints for pkg-config and CMake
cat <<POST
If OpenCV pkg-config files are under ${INSTALL_PREFIX}/lib/pkgconfig, ensure PKG_CONFIG_PATH includes it:
  export PKG_CONFIG_PATH=${INSTALL_PREFIX}/lib/pkgconfig:
Then verify:
  pkg-config --modversion opencv4
POST
