import os
import subprocess
import time
import socket
import pytest
import importlib.machinery
import importlib.util
from pathlib import Path

SCRIPT_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "mc-rclone"))


def get_module():
    loader = importlib.machinery.SourceFileLoader("mc_rclone", SCRIPT_PATH)
    spec = importlib.util.spec_from_loader("mc_rclone", loader)
    mod = importlib.util.module_from_spec(spec)
    loader.exec_module(mod)
    return mod


@pytest.fixture(autouse=True)
def ensure_stopped():
    subprocess.run([SCRIPT_PATH, "stop"], capture_output=True, text=True)
    time.sleep(0.2)
    yield
    subprocess.run([SCRIPT_PATH, "stop"], capture_output=True, text=True)


def test_xdg_environment_variables(tmp_path, monkeypatch):
    custom_cfg = tmp_path / "my_config"
    custom_cache = tmp_path / "my_cache"
    monkeypatch.setenv("XDG_CONFIG_HOME", str(custom_cfg))
    monkeypatch.setenv("XDG_CACHE_HOME", str(custom_cache))

    mod = get_module()
    assert mod.get_xdg_config_home() == custom_cfg
    assert mod.get_xdg_cache_home() == custom_cache
    assert mod.get_config_dir() == custom_cfg / "mc-rclone"
    assert mod.get_cache_dir() == custom_cache / "mc" / "rclone"

    # Verify auto-generation in custom XDG_CONFIG_HOME
    cfg = mod.load_or_create_config()
    assert (custom_cfg / "mc-rclone" / "config.ini").exists()
    assert cfg["port"] == 2123

    # Verify find_rclone_conf picks up custom XDG_CONFIG_HOME/rclone/rclone.conf
    rclone_conf = custom_cfg / "rclone" / "rclone.conf"
    rclone_conf.parent.mkdir(parents=True, exist_ok=True)
    rclone_conf.write_text("[testremote]\ntype = drive\n")
    assert mod.find_rclone_conf() == str(rclone_conf)


def test_load_or_create_config_default(tmp_path):
    mod = get_module()
    cfg_file = tmp_path / "config.ini"
    cfg = mod.load_or_create_config(cfg_file)

    assert cfg_file.exists()
    assert cfg["bind_address"] == "127.0.0.1"
    assert cfg["port"] == 2123
    assert cfg["cache_mode"] == "writes"
    assert cfg["cache_max_size"] == "10G"
    assert cfg["cache_max_age"] == "24h"
    assert cfg["dir_cache_time"] == "5m"
    assert cfg["sftp_probe_timeout"] == 0.2


def test_load_custom_config(tmp_path):
    mod = get_module()
    cfg_file = tmp_path / "config.ini"
    cfg_file.write_text("""
[server]
bind_address = 127.0.0.1
port = 2500

[vfs]
cache_mode = full
cache_max_size = 50G
cache_max_age = 7d
dir_cache_time = 15m

[network]
sftp_probe_timeout = 0.5
""")
    cfg = mod.load_or_create_config(cfg_file)
    assert cfg["port"] == 2500
    assert cfg["cache_mode"] == "full"
    assert cfg["cache_max_size"] == "50G"
    assert cfg["sftp_probe_timeout"] == 0.5


def test_build_rclone_cmd():
    mod = get_module()
    cfg = {
        "bind_address": "127.0.0.1",
        "port": 2123,
        "cache_mode": "writes",
        "cache_max_size": "10G",
        "cache_max_age": "24h",
        "dir_cache_time": "5m",
        "sftp_probe_timeout": 0.2,
    }
    cmd = mod.build_rclone_cmd(cfg, "rem1=rem1: rem2=rem2:")
    assert cmd == [
        "rclone", "serve", "ftp",
        "--addr", "127.0.0.1:2123",
        "--vfs-cache-mode", "writes",
        "--vfs-cache-max-size", "10G",
        "--vfs-cache-max-age", "24h",
        "--dir-cache-time", "5m",
        "--combine-upstreams", "rem1=rem1: rem2=rem2:",
        ":combine:"
    ]


def test_count_user_mc_instances(monkeypatch):
    mod = get_module()
    monkeypatch.setattr("subprocess.check_output", lambda *a, **k: "bash\nmc\npython\nmc\n")
    assert mod.count_user_mc_instances() == 2

    monkeypatch.setattr("subprocess.check_output", lambda *a, **k: "bash\nvim\n")
    assert mod.count_user_mc_instances() == 0


def test_bridge_status_when_stopped():
    res = subprocess.run([SCRIPT_PATH, "status"], capture_output=True, text=True)
    assert res.returncode in (0, 1)
    assert "stopped" in res.stdout.lower() or "not running" in res.stdout.lower()


def test_bridge_start_and_stop():
    my_pid = str(os.getpid())
    res = subprocess.run([SCRIPT_PATH, "start", my_pid], capture_output=True, text=True)
    assert res.returncode == 0

    time.sleep(0.5)
    res_status = subprocess.run([SCRIPT_PATH, "status"], capture_output=True, text=True)
    assert "running" in res_status.stdout.lower()

    # Read port from config or default 2123
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
