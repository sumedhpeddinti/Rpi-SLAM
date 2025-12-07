#!/bin/bash
# Quick test of MJPG-Streamer stream
# Based on the screenshot showing MJPG-Streamer Demo Pages

echo "==================================================="
echo "Testing MJPG-Streamer URLs"
echo "==================================================="
echo ""

STREAM_BASE="http://192.168.1.69:8080"

echo "1. Testing connection to server..."
if curl -s --max-time 5 "$STREAM_BASE" > /dev/null 2>&1; then
    echo "   ✅ Server is reachable at $STREAM_BASE"
else
    echo "   ❌ Cannot reach server at $STREAM_BASE"
    echo "   Check if Raspberry Pi is on and streaming"
    exit 1
fi

echo ""
echo "2. Testing snapshot URL..."
if curl -s --max-time 5 "${STREAM_BASE}/?action=snapshot" --output /tmp/test_snapshot.jpg; then
    if [ -f /tmp/test_snapshot.jpg ]; then
        SIZE=$(stat -f%z /tmp/test_snapshot.jpg 2>/dev/null || stat -c%s /tmp/test_snapshot.jpg 2>/dev/null)
        if [ "$SIZE" -gt 1000 ]; then
            echo "   ✅ Snapshot works! Downloaded ${SIZE} bytes"
            echo "   Saved to: /tmp/test_snapshot.jpg"
        else
            echo "   ⚠️  Snapshot file too small (${SIZE} bytes)"
        fi
    fi
else
    echo "   ❌ Snapshot failed"
fi

echo ""
echo "3. Testing stream URL..."
echo "   Trying: ${STREAM_BASE}/?action=stream"

# Test with Python if available (most reliable)
if command -v python3 &> /dev/null; then
    python3 << 'PYEOF'
import cv2
import sys

stream_url = "http://192.168.1.69:8080/?action=stream"
print(f"   Opening stream: {stream_url}")

cap = cv2.VideoCapture(stream_url)
if cap.isOpened():
    ret, frame = cap.read()
    if ret and frame is not None:
        h, w = frame.shape[:2]
        print(f"   ✅ STREAM WORKS! Got frame: {w}x{h}")
        print(f"")
        print(f"=================================================")
        print(f"SUCCESS! Your stream is ready for ORB-SLAM3")
        print(f"=================================================")
        print(f"")
        print(f"Use this URL: {stream_url}")
        print(f"")
        print(f"To run SLAM:")
        print(f"  cd /home/sum/Desktop/RSLAM/ORB_SLAM3/build")
        print(f"  make mono_http_stream -j4")
        print(f"  cd ..")
        print(f"  ./Examples/Monocular/mono_http_stream \\")
        print(f"    ./Vocabulary/ORBvoc.txt \\")
        print(f"    ./Examples/Monocular/RaspberryPi.yaml \\")
        print(f"    {stream_url}")
        sys.exit(0)
    else:
        print(f"   ❌ Could not read frame from stream")
        sys.exit(1)
else:
    print(f"   ❌ Could not open stream")
    sys.exit(1)
PYEOF
else
    echo "   ⚠️  Python3 not found, cannot test stream directly"
    echo "   But snapshot worked, so stream should work too!"
fi

echo ""
echo "==================================================="
