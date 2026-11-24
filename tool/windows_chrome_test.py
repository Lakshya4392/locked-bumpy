"""Serve the pinned CanvasKit files to Flutter 3.44's Windows browser test host."""
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
from urllib.parse import urlsplit

# Identify only the browser started by this test, even if other Chrome windows are open.
PORT_QUERY = """
Get-CimInstance Win32_Process -Filter "Name='chrome.exe' OR Name='chrome-headless-shell.exe'" |
  Where-Object { $_.CommandLine -and $_.CommandLine.Contains($env:BUMPY_TEST_PROFILE) -and $_.CommandLine.Contains('static/index.html') } |
  Select-Object -First 1 -ExpandProperty CommandLine
"""


def run(command, cwd):
    try:
        from playwright.sync_api import Error, sync_playwright
    except ImportError:
        raise SystemExit("Windows browser tests need the Python playwright package. Install it with python -m pip install playwright.")

    renderer = Path(command[0]).resolve().parent / "cache/flutter_web_sdk/canvaskit"
    with tempfile.TemporaryDirectory(prefix="bumpy-chrome-", ignore_cleanup_errors=True) as profile:
        env = {**os.environ, "TEMP": profile, "TMP": profile, "BUMPY_TEST_PROFILE": profile}
        proc = subprocess.Popen(command, cwd=cwd, env=env)
        try:
            deadline = time.monotonic() + 120
            while proc.poll() is None:
                line = subprocess.run(["powershell", "-NoProfile", "-Command", PORT_QUERY],
                                      env=env, capture_output=True, text=True).stdout
                port = re.search(r"--remote-debugging-port=(\d+)", line)
                if port:
                    break
                if time.monotonic() >= deadline:
                    raise RuntimeError("Flutter did not start the Windows test browser within two minutes.")
                time.sleep(.25)
            else:
                return proc.returncode
            with sync_playwright() as driver:
                browser = driver.chromium.connect_over_cdp("http://127.0.0.1:" + port[1])
                context = browser.contexts[0]

                def local_renderer(route):
                    url = urlsplit(route.request.url)
                    name = url.path.removeprefix("/canvaskit/")
                    names = {"canvaskit.js", "canvaskit.wasm", "chromium/canvaskit.js", "chromium/canvaskit.wasm"}
                    if url.hostname not in {"localhost", "127.0.0.1"} or name not in names:
                        return route.continue_()
                    mime = "application/wasm" if name.endswith(".wasm") else "text/javascript"
                    return route.fulfill(path=renderer / name, content_type=mime)

                context.route("**/canvaskit/**", local_renderer)
                page = next(p for p in context.pages if "/static/index.html" in p.url)
                # The unpatched test host converts this URL to a Windows path and
                # returns 404. Retry if the suite frame already requested the renderer.
                if len(page.frames) > 1 and "_test.html" in page.frames[-1].url:
                    page.frames[-1].evaluate("location.reload()")
                try:
                    while proc.poll() is None:
                        page.wait_for_timeout(250)
                except Error:
                    if not page.is_closed() and browser.is_connected():
                        raise
            return proc.wait()
        finally:
            if proc.poll() is None:
                subprocess.run(["taskkill", "/PID", str(proc.pid), "/T", "/F"], capture_output=True)
                proc.wait()
