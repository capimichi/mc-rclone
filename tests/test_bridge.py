import os
import subprocess
import time
import socket
import pytest

SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "mc-rclone-bridge"))

def test_bridge_status_when_stopped():
    res = subprocess.run([SCRIPT_PATH, "status"], capture_output=True, text=True)
    assert res.returncode in (0, 1)
    assert "stopped" in res.stdout.lower() or "not running" in res.stdout.lower()

def test_bridge_start_and_stop():
    # Start with a dummy parent PID that remains alive during test (current test process)
    my_pid = str(os.getpid())
    res = subprocess.run([SCRIPT_PATH, "start", my_pid], capture_output=True, text=True)
    assert res.returncode == 0

    # Check status
    time.sleep(0.5)
    res_status = subprocess.run([SCRIPT_PATH, "status"], capture_output=True, text=True)
    assert "running" in res_status.stdout.lower()

    # Test port is open
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.settimeout(2)
    conn_result = sock.connect_ex(("127.0.0.1", 2123))
    sock.close()
    assert conn_result == 0

    # Stop bridge
    res_stop = subprocess.run([SCRIPT_PATH, "stop"], capture_output=True, text=True)
    assert res_stop.returncode == 0
    time.sleep(0.5)

    res_after = subprocess.run([SCRIPT_PATH, "status"], capture_output=True, text=True)
    assert "stopped" in res_after.stdout.lower() or "not running" in res_after.stdout.lower()
