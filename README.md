# NSLAM: ORB-SLAM3 hybrid (GPU features + CPU fallback)

This workspace contains a fork of ORB-SLAM3 adapted for Ubuntu 24.04/Linux Mint 22.x with an optional GPU-accelerated feature extractor using OpenCV CUDA. When GPU features are unavailable, it falls back to the original CPU ORB extractor.

Your machine
- OS: Linux Mint 22.2 (Ubuntu 24.04 base)
- GPU: RTX 4050 (Ada)
- CUDA: 12.0 (driver 580.95.05)
- OpenCV: 4.6 (system default)

What was added
- Optional GPU feature extraction in `ORBextractor` using `cv::cuda::ORB`.
- Runtime toggle via YAML settings (no code change required) with automatic CPU fallback.
- CMake updated to accept OpenCV 4.6+ (was 4.12 only).

How to enable GPU features
1) Ensure OpenCV is built with CUDA. The system OpenCV 4.6 is typically CPU-only.

2) Build OpenCV with CUDA using the helper script

```bash
chmod +x /home/sum/Desktop/NSLAM/scripts/build_opencv_cuda.sh
# Install prerequisites (needs sudo) and build OpenCV 4.12 with CUDA for RTX 4050 (SM 8.9)
/home/sum/Desktop/NSLAM/scripts/build_opencv_cuda.sh --install-deps --opencv-version 4.12.0

# Install system-wide (optional, needs sudo)
cd $HOME/opencv-build/build
sudo make install
sudo ldconfig

# Verify the CUDA-enabled OpenCV is visible
pkg-config --modversion opencv4
```

If you want DNN CUDA acceleration (not required for ORB), add `--with-dnn` to the script; ensure cuDNN is present.

3) In your SLAM settings YAML, add optional flags:
```
System.UseGPUFeatures: 1           # 1 to enable, 0 to disable (default 0)
System.MaxGPUImageWidth: 4096      # optional guard
System.MaxGPUImageHeight: 4096     # optional guard
```

Build steps (Mint 22.2)
- Install dependencies (Eigen, Pangolin, SuiteSparse) if you haven't. Be prepared to provide sudo password.
- Adjust paths and run inside `ORB_SLAM3`:

```bash
# Dependencies (approximate)
sudo apt update
sudo apt install -y build-essential cmake git libeigen3-dev libboost-all-dev \
  libglew-dev libpython3-dev python3-numpy ffmpeg libavcodec-dev libavutil-dev \
  libavformat-dev libswscale-dev libdc1394-22-dev libraw1394-dev \
  libjpeg-dev libpng-dev libtiff-dev libx11-dev libxrandr-dev libxi-dev \
  libgl1-mesa-dev libglu1-mesa-dev libsuitesparse-dev

# Pangolin
cd ~ && git clone https://github.com/stevenlovegrove/Pangolin.git
cd Pangolin && git checkout v0.9.2 && mkdir build && cd build
cmake .. && make -j$(nproc)
sudo make install

# Build ORB-SLAM3 (this repo)
cd /home/sum/Desktop/NSLAM/ORB_SLAM3
chmod +x build.sh
./build.sh
```

Notes
- If you keep OpenCV 4.6 CPU-only, compiling works and features run on CPU.
- If you later install OpenCV 4.12+ with CUDA, the same binary will use GPU when `System.UseGPUFeatures: 1` is set and a CUDA device is present.
- To verify CUDA path at runtime, you can turn on `System.UseGPUFeatures: 1` and check performance/time logs.

Quick test (EuRoC)
- Download MH_01_easy and run the monocular example as described in the upstream README.
- Add the `System.UseGPUFeatures` flag in the YAML and compare the extract timings.

Troubleshooting
- If OpenCV with CUDA is not found, the code still compiles; GPU extractor is skipped.
- For CMake errors about OpenCV version, ensure `pkg-config --modversion opencv4` returns 4.6+.
- If Pangolin headers missing, confirm `sudo make install` from Pangolin build completed.

Next steps
- Optionally package a Dockerfile for Mint/Ubuntu 24.04 with CUDA 12.4+ and OpenCV CUDA
- Integrate a runtime log line indicating whether GPU ORB was used per frame.

cd /home/sum/Desktop/NSLAM/ORB_SLAM3
./Examples/Monocular/mono_webcam ./Vocabulary/ORBvoc.txt ./Examples/Monocular/Logitech_UVC.yaml auto

cd /home/sum/Desktop/NSLAM/ORB_SLAM3
./Examples/Monocular/mono_webcam ./Vocabulary/ORBvoc.txt ./Examples/Monocular/Logitech_UVC.yaml auto 640 480

