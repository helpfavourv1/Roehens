#!/usr/bin/env python3
"""Checks that the spike streams answer from this machine.

Reads SPIKE_RTSP_URL and SPIKE_MJPEG_URL from the environment and prints only
host, port and status lines. Credentials and full addresses are never printed.
"""
import os
import socket
import sys
import urllib.request
from urllib.parse import urlparse


def probe_rtsp(raw):
    url = urlparse(raw)
    host, port = url.hostname, url.port or 554
    print(f"RTSP target {host}:{port}")
    try:
        with socket.create_connection((host, port), timeout=8) as sock:
            sock.settimeout(8)
            safe = f"rtsp://{host}:{port}{url.path}"
            sock.sendall(f"OPTIONS {safe} RTSP/1.0\r\nCSeq: 1\r\n\r\n".encode())
            print("  OPTIONS ->", sock.recv(512).decode(errors="replace").splitlines()[0])
            sock.sendall(
                f"DESCRIBE {safe} RTSP/1.0\r\nCSeq: 2\r\nAccept: application/sdp\r\n\r\n".encode()
            )
            print("  DESCRIBE (no auth) ->", sock.recv(1024).decode(errors="replace").splitlines()[0])
    except Exception as error:
        print("  RTSP probe failed:", type(error).__name__, error)


def probe_http(raw):
    url = urlparse(raw)
    print(f"HTTP target {url.hostname}:{url.port or 80}")
    try:
        request = urllib.request.Request(raw, headers={"User-Agent": "Roehens-probe"})
        with urllib.request.urlopen(request, timeout=10) as response:
            print("  status", response.status, response.headers.get("Content-Type"))
            print("  first bytes:", len(response.read(2048)))
    except Exception as error:
        print("  HTTP probe failed:", type(error).__name__, error)


PUBLIC_RTSP = [
    "rtsp://rtsp.stream/pattern",
    "rtsp://rtsp.stream/movie",
    "rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mp4",
    "rtsp://mm2.pcslab.com/mm/7h800.mp4",
]
PUBLIC_MJPEG = [
    "http://webcam.mchcares.com/mjpg/video.mjpg",
    "http://pendelcam.kip.uni-heidelberg.de/mjpg/video.mjpg",
    "http://195.196.36.242/mjpg/video.mjpg",
    "http://camera.buffalotrace.com/mjpg/video.mjpg",
    "http://webcams.hotelcozumel.com.mx:6003/mjpg/video.mjpg",
    "http://77.222.181.11:8080/mjpg/video.mjpg",
]


def rtsp_alive(raw):
    url = urlparse(raw)
    try:
        with socket.create_connection((url.hostname, url.port or 554), timeout=6) as sock:
            sock.settimeout(6)
            sock.sendall(f"OPTIONS {raw} RTSP/1.0\r\nCSeq: 1\r\n\r\n".encode())
            return b" 200" in sock.recv(256).split(b"\r\n")[0]
    except Exception:
        return False


def mjpeg_alive(raw):
    try:
        request = urllib.request.Request(raw, headers={"User-Agent": "Roehens-probe"})
        with urllib.request.urlopen(request, timeout=8) as response:
            kind = response.headers.get("Content-Type", "")
            return response.status == 200 and ("multipart" in kind or "jpeg" in kind)
    except Exception:
        return False


def pick_public():
    chosen = {"public_rtsp": "", "public_mjpeg": ""}
    for raw in PUBLIC_RTSP:
        alive = rtsp_alive(raw)
        print(f"public RTSP {raw} -> {'ALIVE' if alive else 'no answer'}")
        if alive and not chosen["public_rtsp"]:
            chosen["public_rtsp"] = raw
    for raw in PUBLIC_MJPEG:
        alive = mjpeg_alive(raw)
        print(f"public MJPEG {raw} -> {'ALIVE' if alive else 'no answer'}")
        if alive and not chosen["public_mjpeg"]:
            chosen["public_mjpeg"] = raw
    output = os.environ.get("GITHUB_OUTPUT")
    if output:
        with open(output, "a") as handle:
            for key, value in chosen.items():
                handle.write(f"{key}={value}\n")


def main():
    rtsp = os.environ.get("SPIKE_RTSP_URL", "")
    mjpeg = os.environ.get("SPIKE_MJPEG_URL", "")
    if rtsp:
        probe_rtsp(rtsp)
    else:
        print("SPIKE_RTSP_URL is not set")
    if mjpeg:
        probe_http(mjpeg)
    else:
        print("SPIKE_MJPEG_URL is not set")
    pick_public()
    return 0


if __name__ == "__main__":
    sys.exit(main())
