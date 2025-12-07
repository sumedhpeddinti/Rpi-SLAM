# Raspberry Pi Camera to MJPEG Webpage Streaming Guide

This guide provides complete code to capture frames from a Raspberry Pi camera and stream them to an MJPEG webpage accessible via IP address.

## Overview

The solution consists of:
1. **Python Server** - Captures frames from RPi camera and serves MJPEG stream
2. **HTML Webpage** - Displays the live stream via IP address
3. **Configuration** - Network settings and camera parameters

---

## Option 1: Using OpenCV and Flask (Recommended)

### Python Server Code: `rpi_mjpeg_server.py`

```python
#!/usr/bin/env python3
"""
Raspberry Pi MJPEG Streaming Server
Captures frames from camera and streams via HTTP
"""

import cv2
import threading
from flask import Flask, render_template_string, Response
import argparse
from datetime import datetime
import numpy as np

app = Flask(__name__)

# Global variables
frame = None
lock = threading.Lock()
camera_running = False

class CameraCapture:
    def __init__(self, camera_id=0, resolution=(640, 480), fps=30):
        self.camera_id = camera_id
        self.resolution = resolution
        self.fps = fps
        self.cap = None
        self.running = False
        
    def start(self):
        """Initialize and start camera capture"""
        try:
            self.cap = cv2.VideoCapture(self.camera_id)
            
            # Set camera properties
            self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, self.resolution[0])
            self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, self.resolution[1])
            self.cap.set(cv2.CAP_PROP_FPS, self.fps)
            self.cap.set(cv2.CAP_PROP_BUFFERSIZE, 1)  # Reduce buffer for low latency
            
            if not self.cap.isOpened():
                raise Exception("Failed to open camera")
            
            self.running = True
            print(f"Camera initialized: {self.resolution} @ {self.fps} FPS")
            return True
        except Exception as e:
            print(f"Camera initialization error: {e}")
            return False
    
    def read_frame(self):
        """Capture and return a frame"""
        if self.cap and self.cap.isOpened():
            ret, frame = self.cap.read()
            if ret:
                return frame
        return None
    
    def stop(self):
        """Release camera resources"""
        if self.cap:
            self.cap.release()
            self.running = False
            print("Camera released")


def capture_frames(camera):
    """Continuously capture frames from camera"""
    global frame
    
    while camera.running:
        f = camera.read_frame()
        if f is not None:
            with lock:
                frame = f.copy()
        else:
            print("Failed to read frame")
            break


def generate_mjpeg():
    """Generate MJPEG stream"""
    global frame
    
    while True:
        with lock:
            if frame is not None:
                ret, jpeg = cv2.imencode('.jpg', frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
                if ret:
                    # MJPEG boundary format
                    yield (b'--frame\r\n'
                           b'Content-Type: image/jpeg\r\n'
                           b'Content-Length: ' + str(len(jpeg)).encode() + b'\r\n\r\n'
                           + jpeg + b'\r\n')


@app.route('/')
def index():
    """Main webpage displaying the stream"""
    html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Raspberry Pi Camera Stream</title>
        <style>
            body {
                font-family: Arial, sans-serif;
                margin: 0;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                min-height: 100vh;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
            }
            .container {
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.3);
                max-width: 900px;
                width: 100%;
            }
            h1 {
                color: #333;
                text-align: center;
                margin-top: 0;
            }
            .stream-info {
                text-align: center;
                color: #666;
                margin-bottom: 20px;
                font-size: 14px;
            }
            .stream-container {
                text-align: center;
                background: #000;
                padding: 10px;
                border-radius: 5px;
            }
            img {
                max-width: 100%;
                height: auto;
                border-radius: 5px;
            }
            .controls {
                display: flex;
                justify-content: center;
                gap: 10px;
                margin-top: 20px;
            }
            button {
                padding: 10px 20px;
                background: #667eea;
                color: white;
                border: none;
                border-radius: 5px;
                cursor: pointer;
                font-size: 14px;
                transition: background 0.3s;
            }
            button:hover {
                background: #764ba2;
            }
            .stats {
                display: grid;
                grid-template-columns: repeat(2, 1fr);
                gap: 15px;
                margin-top: 20px;
            }
            .stat-box {
                background: #f5f5f5;
                padding: 15px;
                border-radius: 5px;
                text-align: center;
            }
            .stat-label {
                font-size: 12px;
                color: #999;
                text-transform: uppercase;
            }
            .stat-value {
                font-size: 18px;
                color: #333;
                font-weight: bold;
                margin-top: 5px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🎥 Raspberry Pi Camera Stream</h1>
            
            <div class="stream-info">
                <p>Live MJPEG Stream from Camera</p>
                <p id="connection-status">Connecting...</p>
            </div>
            
            <div class="stream-container">
                <img id="stream" src="{{ url_for('video_feed') }}" alt="Camera Stream">
            </div>
            
            <div class="controls">
                <button onclick="refreshStream()">Refresh Stream</button>
                <button onclick="downloadFrame()">Download Frame</button>
            </div>
            
            <div class="stats">
                <div class="stat-box">
                    <div class="stat-label">Resolution</div>
                    <div class="stat-value" id="resolution">640x480</div>
                </div>
                <div class="stat-box">
                    <div class="stat-label">Stream Type</div>
                    <div class="stat-value">MJPEG</div>
                </div>
                <div class="stat-box">
                    <div class="stat-label">Server Status</div>
                    <div class="stat-value" id="server-status">Online</div>
                </div>
                <div class="stat-box">
                    <div class="stat-label">Access IP</div>
                    <div class="stat-value" id="access-ip">Detecting...</div>
                </div>
            </div>
        </div>
        
        <script>
            // Update connection status
            document.getElementById('stream').addEventListener('load', function() {
                document.getElementById('connection-status').textContent = '✓ Connected';
                document.getElementById('connection-status').style.color = 'green';
            });
            
            document.getElementById('stream').addEventListener('error', function() {
                document.getElementById('connection-status').textContent = '✗ Connection Failed';
                document.getElementById('connection-status').style.color = 'red';
            });
            
            // Get server IP
            fetch('/get_ip')
                .then(response => response.json())
                .then(data => {
                    document.getElementById('access-ip').textContent = data.ip + ':' + data.port;
                })
                .catch(e => console.log('IP fetch failed:', e));
            
            function refreshStream() {
                const img = document.getElementById('stream');
                img.src = "{{ url_for('video_feed') }}" + '?t=' + Date.now();
            }
            
            function downloadFrame() {
                const canvas = document.createElement('canvas');
                const img = document.getElementById('stream');
                canvas.width = img.width;
                canvas.height = img.height;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0);
                
                const link = document.createElement('a');
                link.href = canvas.toDataURL('image/jpeg');
                link.download = 'frame_' + new Date().getTime() + '.jpg';
                link.click();
            }
        </script>
    </body>
    </html>
    """
    return render_template_string(html)


@app.route('/video_feed')
def video_feed():
    """MJPEG stream endpoint"""
    return Response(generate_mjpeg(), mimetype='multipart/x-mixed-replace; boundary=frame')


@app.route('/get_ip')
def get_ip():
    """Get server IP and port"""
    import socket
    
    try:
        # Get hostname's IP
        hostname = socket.gethostname()
        ip = socket.gethostbyname(hostname)
    except:
        ip = '127.0.0.1'
    
    return {
        'ip': ip,
        'port': args.port if hasattr(args, 'port') else 5000
    }


def main():
    global args
    
    parser = argparse.ArgumentParser(description='Raspberry Pi MJPEG Stream Server')
    parser.add_argument('--camera', type=int, default=0, help='Camera ID (default: 0)')
    parser.add_argument('--width', type=int, default=640, help='Frame width (default: 640)')
    parser.add_argument('--height', type=int, default=480, help='Frame height (default: 480)')
    parser.add_argument('--fps', type=int, default=30, help='FPS (default: 30)')
    parser.add_argument('--host', default='0.0.0.0', help='Server host (default: 0.0.0.0)')
    parser.add_argument('--port', type=int, default=5000, help='Server port (default: 5000)')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    
    args = parser.parse_args()
    
    # Initialize camera
    camera = CameraCapture(
        camera_id=args.camera,
        resolution=(args.width, args.height),
        fps=args.fps
    )
    
    if not camera.start():
        print("Failed to start camera")
        return
    
    # Start capture thread
    capture_thread = threading.Thread(target=capture_frames, args=(camera,), daemon=True)
    capture_thread.start()
    
    print(f"\n{'='*50}")
    print(f"MJPEG Server Started")
    print(f"{'='*50}")
    print(f"Camera: {args.width}x{args.height} @ {args.fps} FPS")
    print(f"Host: {args.host}:{args.port}")
    print(f"URL: http://<your-rpi-ip>:{args.port}")
    print(f"{'='*50}\n")
    
    try:
        app.run(host=args.host, port=args.port, debug=args.debug, threaded=True)
    except KeyboardInterrupt:
        print("\nShutting down...")
    finally:
        camera.stop()


if __name__ == '__main__':
    main()
```

### Installation on Raspberry Pi

```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install dependencies
sudo apt-get install -y python3-pip python3-opencv libatlas-base-dev

# Install Python packages
pip3 install flask opencv-python

# Make script executable
chmod +x rpi_mjpeg_server.py
```

### Run the Server

```bash
# Basic usage (default: 640x480, 30 FPS, port 5000)
python3 rpi_mjpeg_server.py

# Custom resolution and port
python3 rpi_mjpeg_server.py --width 1280 --height 720 --fps 30 --port 8080

# Debug mode
python3 rpi_mjpeg_server.py --debug
```

---

## Option 2: Using picamera and streaming_server (Lightweight)

### Python Server Code: `rpi_picamera_stream.py`

```python
#!/usr/bin/env python3
"""
Lightweight Raspberry Pi Camera MJPEG Streaming
Uses picamera library for better performance on RPi
"""

import io
import time
import threading
from picamera import PiCamera
from picamera.array import PiRGBArray
from flask import Flask, render_template_string, Response
import argparse

app = Flask(__name__)
frame_buffer = None
lock = threading.Lock()


class PiCameraStream:
    def __init__(self, resolution=(640, 480), framerate=30):
        self.resolution = resolution
        self.framerate = framerate
        self.camera = PiCamera()
        self.running = False
        
    def start(self):
        """Initialize camera"""
        try:
            self.camera.resolution = self.resolution
            self.camera.framerate = self.framerate
            self.camera.vflip = False
            self.camera.hflip = False
            # Warmup camera
            time.sleep(2)
            self.running = True
            print(f"PiCamera initialized: {self.resolution} @ {self.framerate} FPS")
            return True
        except Exception as e:
            print(f"Camera error: {e}")
            return False
    
    def get_frame(self):
        """Capture frame as JPEG bytes"""
        try:
            stream = io.BytesIO()
            self.camera.capture(stream, format='jpeg', quality=80, use_video_port=True)
            stream.seek(0)
            return stream.read()
        except Exception as e:
            print(f"Capture error: {e}")
            return None
    
    def stop(self):
        """Release camera"""
        self.camera.close()
        self.running = False


def generate():
    """Generate MJPEG stream"""
    camera = PiCameraStream(resolution=(640, 480), framerate=30)
    if not camera.start():
        return
    
    try:
        while camera.running:
            frame_data = camera.get_frame()
            if frame_data:
                yield (b'--frame\r\n'
                       b'Content-Type: image/jpeg\r\n'
                       b'Content-Length: ' + str(len(frame_data)).encode() + b'\r\n\r\n'
                       + frame_data + b'\r\n')
            else:
                time.sleep(0.01)
    finally:
        camera.stop()


@app.route('/')
def index():
    """Main webpage"""
    return render_template_string('''
    <!DOCTYPE html>
    <html>
    <head>
        <title>RPi Camera Stream</title>
        <style>
            body { text-align: center; font-family: Arial; padding: 20px; }
            img { max-width: 90%; height: auto; }
            h1 { color: #333; }
        </style>
    </head>
    <body>
        <h1>Raspberry Pi Camera Stream</h1>
        <img src="{{ url_for('video_feed') }}" alt="Stream">
    </body>
    </html>
    ''')


@app.route('/video_feed')
def video_feed():
    """Stream endpoint"""
    return Response(generate(), mimetype='multipart/x-mixed-replace; boundary=frame')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--host', default='0.0.0.0')
    parser.add_argument('--port', type=int, default=5000)
    args = parser.parse_args()
    
    print(f"\nStarting stream on http://<rpi-ip>:{args.port}\n")
    app.run(host=args.host, port=args.port, threaded=True)
```

### Install picamera

```bash
sudo apt-get install -y python3-picamera
pip3 install flask
```

---

## Option 3: Using GStreamer (High Performance)

### GStreamer Server Script: `rpi_gstreamer_stream.sh`

```bash
#!/bin/bash
# GStreamer MJPEG streaming - High performance option

# Set camera parameters
WIDTH=640
HEIGHT=480
BITRATE=2000
FRAMERATE=30/1

# Get RPi IP
RPI_IP=$(hostname -I | awk '{print $1}')

echo "Starting GStreamer MJPEG Stream"
echo "IP: $RPI_IP:5000"
echo "Resolution: ${WIDTH}x${HEIGHT}"
echo "Bitrate: ${BITRATE} kbps"

# GStreamer pipeline for MJPEG streaming
gst-launch-1.0 -v \
  libcamerasrc ! \
  video/x-raw,width=$WIDTH,height=$HEIGHT,framerate=$FRAMERATE ! \
  jpegenc quality=80 ! \
  multipartmux ! \
  tcpserversink host=0.0.0.0 port=5000
```

---

## Configuration Files

### systemd Service: `rpi-camera-stream.service`

```ini
[Unit]
Description=Raspberry Pi Camera MJPEG Stream
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/camera_stream
ExecStart=/usr/bin/python3 /home/pi/camera_stream/rpi_mjpeg_server.py --host 0.0.0.0 --port 5000
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

### Install as service:

```bash
sudo cp rpi-camera-stream.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable rpi-camera-stream.service
sudo systemctl start rpi-camera-stream.service
sudo systemctl status rpi-camera-stream.service
```

---

## Network Configuration

### Finding Your Raspberry Pi IP

```bash
# Method 1: On RPi itself
hostname -I

# Method 2: From another computer on network
nmap -sn 192.168.1.0/24  # Adjust subnet to your network

# Method 3: Check router DHCP clients
# Login to your router and check connected devices
```

### Making IP Static (Optional)

Edit `/etc/dhcpcd.conf`:

```bash
sudo nano /etc/dhcpcd.conf
```

Add at the end:

```
interface eth0
static ip_address=192.168.1.100/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8 8.8.4.4

interface wlan0
static ip_address=192.168.1.101/24
static routers=192.168.1.1
static domain_name_servers=8.8.8.8 8.8.4.4
```

---

## Client HTML Files

### Mobile-Friendly Viewer: `viewer.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>RPi Camera Viewer</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #1a1a1a;
            color: #fff;
            padding: 10px;
        }
        .app-container {
            max-width: 800px;
            margin: 0 auto;
        }
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
        }
        h1 { font-size: 24px; margin-bottom: 5px; }
        .ip-input {
            background: rgba(255,255,255,0.1);
            border: 1px solid rgba(255,255,255,0.3);
            padding: 10px;
            border-radius: 5px;
            color: #fff;
            margin-top: 10px;
            width: 100%;
            font-size: 14px;
        }
        .stream-wrapper {
            position: relative;
            background: #000;
            border-radius: 8px;
            overflow: hidden;
            margin-bottom: 20px;
            aspect-ratio: 16/9;
        }
        .stream-wrapper img {
            width: 100%;
            height: 100%;
            object-fit: contain;
        }
        .controls {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 10px;
            margin-bottom: 20px;
        }
        button {
            padding: 12px;
            background: #667eea;
            border: none;
            color: white;
            border-radius: 5px;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.3s;
        }
        button:hover {
            background: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
        }
        button:active {
            transform: translateY(0);
        }
        .status {
            background: #2a2a2a;
            padding: 15px;
            border-radius: 5px;
            font-size: 14px;
        }
        .status-item {
            display: flex;
            justify-content: space-between;
            padding: 5px 0;
        }
        .status-label { color: #999; }
        .status-value { color: #0f0; font-weight: bold; }
        .error { color: #f44; }
        @media (max-width: 600px) {
            h1 { font-size: 20px; }
            .controls { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    <div class="app-container">
        <header>
            <h1>🎥 RPi Camera Viewer</h1>
            <input type="text" id="rpiIp" class="ip-input" placeholder="Enter RPi IP (e.g., 192.168.1.100:5000)" value="localhost:5000">
        </header>
        
        <div class="stream-wrapper">
            <img id="stream" src="" alt="No stream">
        </div>
        
        <div class="controls">
            <button onclick="connectStream()">🔗 Connect</button>
            <button onclick="refreshStream()">🔄 Refresh</button>
            <button onclick="downloadFrame()">💾 Download</button>
            <button onclick="toggleFullscreen()">⛶ Fullscreen</button>
        </div>
        
        <div class="status">
            <div class="status-item">
                <span class="status-label">Status:</span>
                <span class="status-value" id="status">Disconnected</span>
            </div>
            <div class="status-item">
                <span class="status-label">Connected IP:</span>
                <span class="status-value" id="connectedIp">-</span>
            </div>
            <div class="status-item">
                <span class="status-label">Last Update:</span>
                <span class="status-value" id="lastUpdate">-</span>
            </div>
        </div>
    </div>
    
    <script>
        const streamImg = document.getElementById('stream');
        const statusEl = document.getElementById('status');
        const connectedIpEl = document.getElementById('connectedIp');
        const lastUpdateEl = document.getElementById('lastUpdate');
        const ipInput = document.getElementById('rpiIp');
        
        let connected = false;
        
        function connectStream() {
            const ip = ipInput.value.trim();
            if (!ip) {
                alert('Please enter RPi IP address');
                return;
            }
            
            const url = `http://${ip}/video_feed`;
            streamImg.src = url;
            streamImg.onerror = () => {
                statusEl.textContent = 'Error - Cannot connect';
                statusEl.classList.add('error');
                connected = false;
            };
            
            connectedIpEl.textContent = ip;
        }
        
        function refreshStream() {
            if (streamImg.src) {
                streamImg.src = streamImg.src.split('?')[0] + '?t=' + Date.now();
            }
        }
        
        function downloadFrame() {
            const canvas = document.createElement('canvas');
            canvas.width = streamImg.width;
            canvas.height = streamImg.height;
            const ctx = canvas.getContext('2d');
            ctx.drawImage(streamImg, 0, 0);
            
            const link = document.createElement('a');
            link.href = canvas.toDataURL('image/jpeg');
            link.download = `rpi-frame-${Date.now()}.jpg`;
            link.click();
        }
        
        function toggleFullscreen() {
            streamImg.parentElement.requestFullscreen();
        }
        
        streamImg.addEventListener('load', () => {
            statusEl.textContent = 'Connected';
            statusEl.classList.remove('error');
            connected = true;
            lastUpdateEl.textContent = new Date().toLocaleTimeString();
        });
        
        // Try to connect to localhost by default
        ipInput.value = window.location.hostname + ':5000';
        connectStream();
    </script>
</body>
</html>
```

---

## Troubleshooting

### Camera Not Found
```bash
# Check if camera is enabled
vcgencmd get_camera

# Enable camera in raspi-config
sudo raspi-config
# → Interface Options → Camera → Enable
```

### Port Already in Use
```bash
# Find what's using port 5000
sudo lsof -i :5000

# Kill the process
sudo kill -9 <PID>

# Or use a different port
python3 rpi_mjpeg_server.py --port 8080
```

### Network Connection Issues
```bash
# Check if RPi is on network
ping <rpi-ip>

# Check if port is open
telnet <rpi-ip> 5000
```

### Low FPS or High Latency
- Reduce resolution: `--width 320 --height 240`
- Lower quality: Modify `IMWRITE_JPEG_QUALITY` to 60-70
- Reduce FPS: `--fps 15`

---

## Performance Optimization Tips

1. **Resolution**: Lower resolution = better performance
   - 320x240: Ultra-light
   - 640x480: Balanced
   - 1280x720: High quality (slower)

2. **JPEG Quality**: Trade quality for speed
   - Quality 60-70: Fast, good quality
   - Quality 80-90: Better quality, slower

3. **Network**: Use Ethernet for best stability

4. **Threading**: Enable in Flask with `threaded=True`

---

## Security Considerations

⚠️ **WARNING**: Default setup is open to network. Add authentication:

```python
from functools import wraps
from flask import request, abort

# Add to rpi_mjpeg_server.py
USERNAME = 'admin'
PASSWORD = 'your_secure_password'

def require_auth(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        auth = request.authorization
        if not auth or auth.password != PASSWORD:
            return abort(401)
        return f(*args, **kwargs)
    return decorated

@app.route('/video_feed')
@require_auth
def video_feed():
    return Response(generate_mjpeg(), mimetype='multipart/x-mixed-replace; boundary=frame')
```

---

## Testing from Another Machine

```bash
# SSH to RPi
ssh pi@<rpi-ip>

# Run server
python3 rpi_mjpeg_server.py

# From another computer, open browser
http://<rpi-ip>:5000

# Or test with curl
curl http://<rpi-ip>:5000/video_feed > test_stream.mjpeg

# View with ffplay
ffplay test_stream.mjpeg
```

---

## Integration with ORB-SLAM3

To integrate with your RSLAM project:

```python
# In your ORB-SLAM3 code:
import cv2
from flask import Flask

# Capture from MJPEG stream
cap = cv2.VideoCapture('http://<rpi-ip>:5000/video_feed')

# Use frames with ORB-SLAM3
while True:
    ret, frame = cap.read()
    if not ret:
        break
    
    # Process with ORB-SLAM3
    # slam.TrackMonocular(frame, timestamp)
```

---

## Additional Resources

- [OpenCV Documentation](https://docs.opencv.org/)
- [Flask Documentation](https://flask.palletsprojects.com/)
- [Raspberry Pi Camera Guide](https://www.raspberrypi.org/documentation/cameras/)
- [GStreamer Documentation](https://gstreamer.freedesktop.org/)

---

**Last Updated**: December 2025
**Author**: Robotics Development Team
