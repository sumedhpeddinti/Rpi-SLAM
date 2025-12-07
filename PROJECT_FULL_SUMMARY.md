# Project Summary — Monocular SLAM over HTTP Video Streams

## Overview
This document summarizes a monocular SLAM system based on ORB-SLAM3 that ingests live video streams over HTTP (MJPEG). The integration provides a generalized input layer for remote cameras while maintaining real-time performance through optional GPU-accelerated feature extraction. The content here is written in a thesis-friendly, technology-agnostic style.

## System Components
- SLAM Core: ORB-SLAM3 (tracking, local mapping, loop closing, relocalization).
- Video Ingestion: OpenCV VideoCapture for HTTP MJPEG streams (typically via FFMPEG backend).
- Acceleration: CUDA-enabled ORB extractor (if supported by the OpenCV build and GPU hardware).
- Visualization: Pangolin viewer; trajectories saved as `KeyFrameTrajectory.txt`.

## Implementation Highlights
- Input Module: `Examples/Monocular/mono_http_stream.cc` reads HTTP MJPEG streams, timestamps frames, converts to grayscale, and feeds them to the SLAM tracker. Basic reconnection and diagnostics are included.
- Configuration: `Examples/Monocular/RaspberryPi.yaml` holds camera intrinsics (fx, fy, cx, cy) and distortion coefficients, plus ORB extractor and system parameters. Keys follow ORB-SLAM3’s expected schema (e.g., `Camera.fx`, `Camera.fy`).
- Build Integration: CMake target added for the HTTP-stream example; dependencies include OpenCV, Pangolin, Eigen, g2o, DBoW2, Sophus.

## Usage (Generalized)
1. Provide a monocular camera that streams MJPEG over HTTP (any endpoint with continuous JPEG frames).
2. Build the project with CMake (use the repository’s `build.sh` or equivalent).
3. Run the HTTP-stream example, passing the vocabulary file, the camera configuration YAML, and the stream URL.
4. Observe the viewer and logs; the system prints per-frame throughput (FPS) and tracking status.

## Calibration Guidance
- Use a chessboard or Charuco target to calibrate focal lengths, principal point, and distortion. Update the YAML with measured intrinsics for the exact resolution used. Accurate calibration improves tracking stability and map consistency.

## Performance Characteristics (Representative)
- Ingesting VGA-resolution MJPEG streams (e.g., 640×480) is stable on typical workstations.
- End-to-end processing throughput around the mid-teens FPS is common when using GPU-accelerated ORB extraction; overall throughput depends on scene dynamics, network latency, resolution, and CPU capacity for matching and optimization.

## Troubleshooting (Generalized)
- If stream fails to open: verify URL reachability, backend availability (FFMPEG), and that the stream serves continuous MJPEG frames.
- If configuration fails (e.g., missing `Camera.fx`): ensure the YAML keys match ORB-SLAM3’s expected names and that values are numeric.
- If tracking is unstable: reduce motion speed, improve lighting, increase feature count, or lower input resolution/latency.
- If visualization fails: validate OpenGL context and Pangolin installation.

## Limitations
- MJPEG over HTTP introduces compression artifacts and transport latency/jitter, which can degrade tracking during fast motion.
- Monocular scale ambiguity remains unless additional sensing (e.g., IMU) is fused.
- Dependence on the availability and configuration of OpenCV/FFMPEG and GPU drivers.

## Future Directions
- Robust streaming: adaptive buffering and frame-dropping strategies to stabilize latency.
- Sensor fusion: integrate inertial measurements to improve robustness and resolve scale.
- Auto-tuning: dynamically adjust ORB parameters based on scene content and bandwidth.
- Deployment tooling: automated calibration pipeline and containerized services for reproducible field deployments.

## Cross-reference
For a thesis-ready narrative (problem statement, methodology, evaluation, and conclusions), see `THESIS_SUMMARY.md` in the repository root.
