# Monocular SLAM with HTTP Video Streams: System Design, Implementation, and Evaluation

## Abstract
We present a monocular Simultaneous Localization and Mapping (SLAM) system based on ORB-SLAM3 that ingests live video over HTTP (MJPEG) from a low-cost embedded camera. The contribution is a practical integration layer that enables network-streamed sensing while preserving real-time performance through GPU-accelerated feature extraction. We document the system architecture, implementation decisions, and empirical evaluation, and discuss limitations and future directions for robust, networked SLAM in resource-constrained environments.

## 1. Introduction
Vision-based SLAM enables motion estimation and mapping using a single camera, offering an affordable alternative to LiDAR or multi-camera systems. Many deployments require remote or embedded cameras that stream over a network (e.g., MJPEG/HTTP). This work generalizes monocular SLAM to such video sources, addressing latency, bandwidth, and compute constraints while maintaining accuracy and real-time operation.

## 2. Problem Statement and Objectives
- Ingest remote monocular video over HTTP in real time.
- Maintain SLAM performance comparable to local capture while accommodating network variability.
- Exploit GPU acceleration for feature extraction to improve throughput on commodity hardware.
- Provide a reproducible, configurable pipeline suitable for research and field deployments.

## 3. System Overview
- SLAM Core: ORB-SLAM3 (tracking, local mapping, loop closing, relocalization).
- Video Ingestion: OpenCV VideoCapture (FFMPEG backend) for HTTP MJPEG streams.
- Acceleration: CUDA-enabled ORB extractor when available.
- Visualization and Trajectory: Pangolin viewer; trajectories saved to `KeyFrameTrajectory.txt`.

### 3.1 Data Flow
1. Network camera produces MJPEG frames (HTTP endpoint).
2. Host ingests frames via OpenCV, timestamps them, and converts to grayscale.
3. Frames enter the ORB-SLAM3 tracking pipeline; keyframes trigger local mapping and loop closing.
4. Results (pose estimates and map) are rendered; trajectories are logged to disk.

## 4. Implementation Details
- Input Module: `mono_http_stream` example reads HTTP streams and includes reconnection and diagnostics.
- Configuration: YAML camera intrinsics (fx, fy, cx, cy) and distortion; ORB extractor parameters (nFeatures, scaleFactor, nLevels) tunable.
- Build Integration: CMake target added; dependencies include OpenCV, Pangolin, Eigen, g2o, DBoW2, Sophus.
- Timing and Metrics: Per-frame processing time and FPS reported for throughput characterization.

### 4.1 Camera Model and Parameters
- Pinhole camera model with radial-tangential distortion.
- Intrinsics should be calibrated for the specific lens/resolution; default parameters provided as placeholders.

## 5. Evaluation Methodology
- Setup: A networked monocular camera streaming MJPEG over HTTP.
- Procedure: Run SLAM for several minutes under typical motion (translation/rotation), record FPS, tracking events (relocalization), and map initialization statistics.
- Metrics:
  - Throughput (FPS) and latency estimates.
  - Tracking robustness (frequency of relocalization or tracking loss).
  - Map quality (number of points at initialization, keyframe count).

## 6. Results (Representative)
- Stream ingestion stable at VGA resolution (e.g., 640×480) with nominal 25 FPS input.
- End-to-end SLAM processing throughput observed around 14 FPS on a commodity GPU-enabled workstation.
- Successful map initialization with hundreds of points; occasional tracking loss events addressed by built-in relocalization.

Note: Exact metrics depend on scene content, motion profile, network conditions, resolution, and hardware. Provide calibration and controlled datasets for rigorous quantitative comparison.

## 7. Discussion
- Network Latency: MJPEG over HTTP introduces transport delay and jitter; buffering should be minimized. Wired Ethernet improves stability.
- Compute Bottlenecks: While GPU accelerates ORB extraction, matching and bundle adjustment remain CPU-bound.
- Calibration: Accurate intrinsics materially affect tracking stability and map consistency. Calibration should be performed for the target camera and resolution.

## 8. Limitations
- MJPEG compression artifacts and variable latency can impair tracking under fast motion.
- Monocular scale ambiguity persists; scale-aware evaluation requires known baselines or inertial fusion.
- Dependence on OpenCV/FFMPEG backend availability and configuration.

## 9. Future Work
- Robust streaming: Adaptive buffering, backpressure, and frame-dropping strategies to stabilize latency.
- Multi-sensor fusion: Integrate IMU (RGB-D-Inertial) to improve robustness and resolve scale.
- Adaptive parameters: Auto-tuning of ORB features based on scene and bandwidth.
- Deployment tooling: Automated calibration pipeline and containerization/system services for reproducible field use.

## 10. Reproducibility Checklist
- Provide:
  - Source code for HTTP ingestion example (`mono_http_stream`).
  - Calibration data and YAML for camera intrinsics/distortion.
  - Hardware specs (CPU/GPU, OS, OpenCV version, CUDA availability).
  - Stream configuration (resolution, nominal FPS, compression).
  - Test scenes and motion profiles.

## 11. Conclusion
We demonstrate that monocular SLAM can operate effectively on network-delivered video streams with modest hardware, leveraging GPU acceleration where available. The integration is practical, configurable, and suitable for research and deployment, with clear avenues for improving robustness and accuracy.

## References
- Mur-Artal, J., Tardós, J.D. ORB-SLAM2/3 papers.
- OpenCV and FFMPEG documentation for VideoCapture and MJPEG streams.
- Pangolin visualization library.
