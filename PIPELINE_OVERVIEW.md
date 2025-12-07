# End-to-End Pipeline Overview: Raspberry Pi → Laptop → ORB-SLAM3

This document explains, step by step, how frames are captured on the Raspberry Pi, streamed over the network, ingested on the laptop, processed by the SLAM pipeline, and how outputs are generated.

## 1. Raspberry Pi: Image Capture
- Hardware: Single monocular camera (e.g., Pi Camera or USB UVC camera) connected to Raspberry Pi.
- Capture: The camera produces raw frames at a configured resolution and frame rate (e.g., 640×480 @ 25 FPS).
- Driver: The camera is accessed via the Pi’s camera stack (libcamera or UVC) by the streaming software.

## 2. Raspberry Pi: Encoding and HTTP Streaming
- Encoder: Frames are encoded as JPEG images (MJPEG sequence).
- Streamer: A lightweight HTTP server (e.g., mjpg-streamer) serves a continuous multipart MJPEG stream.
  - Typical invocation: `mjpg_streamer -i "input_uvc.so -y -r 640x480 -f 25" -o "output_http.so -p 8080 -w ./www"`
- Endpoint: The stream is available at an HTTP URL (e.g., `http://<pi-address>:8080/?action=stream`).
- Transport: Over LAN/Wi‑Fi using HTTP; each frame is a JPEG in a multipart response.

## 3. Laptop: Stream Ingestion
- Client: OpenCV’s `VideoCapture` opens the HTTP MJPEG URL.
- Backend: FFMPEG (via OpenCV) parses the multipart stream and decodes JPEG frames into CPU memory.
- Timestamping: Each decoded frame is timestamped on arrival by the client and handed off to the SLAM tracker.
- Resilience: The ingestion module includes basic retries/reconnection if the stream temporarily fails.

### How the pixels travel over Wi‑Fi (layer by layer)
- Sensor → Encoder: The camera sensor produces pixel data; the Pi encodes each frame as a JPEG image (lossy compression).
- Application Layer (HTTP multipart MJPEG): The Pi’s HTTP server wraps each JPEG as a part in a continuous multipart response (`Content-Type: multipart/x-mixed-replace`). Each part has headers (e.g., `Content-Length`) followed by JPEG bytes.
- Transport Layer (TCP): The HTTP stream rides over a persistent TCP connection. TCP segments carry the JPEG bytes reliably with in-order delivery and retransmissions on loss.
- Network & Link Layers (IP over 802.11): TCP/IP packets are carried over your Wi‑Fi (802.11) link. Access point handles medium access; packets may be buffered, retried, and rate-controlled.
- Host Ingestion: On the laptop, the socket delivers TCP byte streams to FFMPEG. FFMPEG scans multipart boundaries, extracts JPEG payloads, and decodes them into pixel buffers (e.g., BGR). OpenCV then exposes these decoded frames via `VideoCapture.read()`.
- Timing & Buffering: OS/network stacks and FFMPEG maintain small buffers. Larger buffers increase robustness but add latency; smaller buffers reduce latency but risk underflow on jittery links.

## 4. Pre-processing on Laptop
- Colorspace: Frames are converted to grayscale (ORB features operate on intensity).
- Optional GPU steps (if CUDA-enabled OpenCV): CLAHE, pyramid construction, blur, and ORB feature extraction executed on the GPU.
- Normalization: Image pyramid and scale factors prepared according to configuration (YAML parameters).

## 5. ORB-SLAM3: Tracking Pipeline
- Feature Detection & Description: ORB keypoints and binary descriptors computed per frame.
- Initial Pose Estimation: Motion model or homography/essential matrix estimation aligns current frame to the map.
- Keyframe Decision: New keyframes are inserted based on heuristics (parallax, tracking quality, time).
- Data Association: Match descriptors to map points; outlier rejection with geometric constraints.

## 6. ORB-SLAM3: Mapping and Optimization
- Local Mapping: Triangulates new map points, culls spurious points, refines local structure.
- Loop Closing: Detects loops via place recognition (DBoW2), performs pose graph optimization.
- Global Optimization: Bundle adjustment refines camera poses and 3D points, improving accuracy.
- Relocalization: If tracking is lost, place recognition and pose estimation re-establish alignment.

## 7. Outputs and Artifacts
- Visualization: Pangolin viewer renders the current camera pose and sparse map in real time.
- Trajectory Logs: `KeyFrameTrajectory.txt` written on shutdown (keyframe poses in TUM format).
- Diagnostics: Console logs report FPS, tracking state, relocalization events, and map statistics.
- Optional Exports: With minor extensions, full frame-to-frame trajectories or maps can be exported for evaluation.

## 8. Configuration and Tuning
- Camera Intrinsics: YAML provides `Camera.fx`, `Camera.fy`, `Camera.cx`, `Camera.cy`, and distortion coefficients (`k1..k3`, `p1..p2`). Accurate calibration improves tracking.
- ORB Parameters: `ORBextractor.nFeatures`, `scaleFactor`, `nLevels` control feature density and pyramid depth.
- Stream Parameters: Resolution and JPEG quality on the Pi affect bandwidth, latency, and visual fidelity.
- System Settings: Threads (Tracking, LocalMapping, LoopClosing) start automatically; viewer can be toggled.

## 9. Data Flow Summary (Text Diagram)
```
[Pi Camera] → raw frames → [MJPEG Encoder] → [HTTP Server (mjpg-streamer)]
      → HTTP (LAN) → [OpenCV VideoCapture (FFMPEG)] → decoded frames
      → [Pre-processing (gray, pyramid, optional GPU)]
      → [ORB Features (keypoints+descriptors)]
      → [Tracking] ↔ [Local Mapping] ↔ [Loop Closing]
      → [Bundle Adjustment]
      → [Viewer] + [Trajectory Log]
```

## 10. Typical Performance and Constraints
- Throughput: Mid-teens FPS with GPU-accelerated extraction; bounded by CPU-side matching and optimization.
- Latency: Network transport adds delay/jitter; wired Ethernet improves stability.
- Robustness: Relocalization handles temporary tracking loss; accurate intrinsics reduce drift and failure.

## 11. Reproducibility Checklist
- Provide the stream URL and configuration (resolution/FPS), YAML intrinsics, hardware specs, and OpenCV build details.
- Ensure FFMPEG backend is available in OpenCV; verify reachability of the HTTP endpoint.
- Calibrate the camera for the exact resolution used.

## 12. Notes for Thesis Integration
- Use this pipeline description in Methods. Cross-reference `THESIS_SUMMARY.md` for problem framing and evaluation methodology.
- Include diagrams derived from the text diagram; quantify latency (network + decoding + processing) and throughput (FPS).
