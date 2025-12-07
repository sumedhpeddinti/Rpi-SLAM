#!/usr/bin/env bash
# Safe, thermally-friendly build for ORB_SLAM3
# - Limits parallelism to reduce CPU heat
# - Uses ccache if available to shorten rebuilds
# - Shows brief progress

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/ORB_SLAM3/build"

JOBS=${JOBS:-4}

# Prefer ccache when present
if command -v ccache >/dev/null 2>&1; then
  echo "[build_safe] Enabling ccache"
  export CC="ccache gcc"
  export CXX="ccache g++"
fi

mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure (reconfigure if CMakeCache is older than CMakeLists)
if [ ! -f CMakeCache.txt ]; then
  echo "[build_safe] Configuring CMake..."
  cmake .. -DCMAKE_BUILD_TYPE=Release
fi

echo "[build_safe] Building with -j${JOBS} ..."
make -j"${JOBS}" 2>&1 | sed -u -n '1,5p; $p'

echo "[build_safe] Done. Binaries are under $ROOT_DIR/ORB_SLAM3/Examples"
