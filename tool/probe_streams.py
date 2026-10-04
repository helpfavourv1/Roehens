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
    return 0


if __name__ == "__main__":
    sys.exit(main())
