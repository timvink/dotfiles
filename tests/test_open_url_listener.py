import base64
import os
import socket
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

SOURCE = (
    Path(__file__).resolve().parents[1] / "dot_local/bin/executable_open-url-listener"
)
PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/aXcAAAAASUVORK5CYII="
)


class ClipboardBridgeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="mac-clipboard-bridge-")
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.bin = self.home / ".local/bin"
        self.bin.mkdir(parents=True)
        self.log = self.home / "commands.log"
        self.image = self.home / "image.png"
        self.text = self.home / "text.txt"
        self.text.write_bytes(b"")
        common = """#!/usr/bin/env python3
import os,sys
from pathlib import Path
assert os.environ['LC_ALL'] == 'en_US.UTF-8'
with Path(os.environ['CLIPBOARD_TEST_LOG']).open('a') as log: log.write(Path(sys.argv[0]).name+'\\n')
delay=Path(os.environ['CLIPBOARD_TEST_DELAY']) / Path(sys.argv[0]).name
if delay.exists():
    import time
    time.sleep(float(delay.read_text()))
"""
        (self.bin / "pngpaste").write_text(
            common
            + """image=Path(os.environ['CLIPBOARD_TEST_IMAGE'])
image.with_suffix('.args').write_text(sys.argv[1])
if not image.exists():sys.exit(1)
if sys.argv[1] == '-':
    sys.stdout.buffer.write(image.read_bytes())
else:
    # pngpaste uses writeToFile:atomically:YES, replacing the destination inode.
    output=Path(sys.argv[1])
    replacement=output.with_suffix('.replacement')
    replacement.write_bytes(image.read_bytes())
    replacement.replace(output)
"""
        )
        pbpaste = self.bin / "pbpaste"
        pbpaste.write_text(
            common
            + """sys.stdout.buffer.write(Path(os.environ['CLIPBOARD_TEST_TEXT']).read_bytes())
"""
        )
        pbcopy = self.bin / "pbcopy"
        pbcopy.write_text(
            common
            + """result=Path(os.environ['CLIPBOARD_TEST_COPY_RESULT'])
if result.exists():sys.exit(int(result.read_text()))
Path(os.environ['CLIPBOARD_TEST_TEXT']).write_bytes(sys.stdin.buffer.read())
"""
        )
        for file in self.bin.iterdir():
            file.chmod(0o755)
        with socket.socket() as probe:
            probe.bind(("127.0.0.1", 0))
            self.port = probe.getsockname()[1]
        source = (
            SOURCE.read_text()
            .replace("my $PORT = 2489;", f"my $PORT = {self.port};")
            .replace("'/usr/bin/pbpaste'", f"'{pbpaste}'")
            .replace("'/usr/bin/pbcopy'", f"'{pbcopy}'")
        )
        self.listener = self.home / "listener.pl"
        self.listener.write_text(source)
        env = dict(
            os.environ,
            HOME=str(self.home),
            CLIPBOARD_TEST_LOG=str(self.log),
            CLIPBOARD_TEST_IMAGE=str(self.image),
            CLIPBOARD_TEST_TEXT=str(self.text),
            CLIPBOARD_TEST_DELAY=str(self.home / "delay"),
            CLIPBOARD_TEST_COPY_RESULT=str(self.home / "copy-result"),
        )
        self.process = subprocess.Popen(
            ["perl", str(self.listener)],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        self.addCleanup(self.stop)
        deadline = time.monotonic() + 5
        while time.monotonic() < deadline:
            try:
                with socket.create_connection(("127.0.0.1", self.port), timeout=0.1):
                    break
            except OSError:
                if self.process.poll() is not None:
                    self.fail(self.process.communicate()[1].decode())
                time.sleep(0.02)
        else:
            self.fail("Listener did not start")

    def stop(self):
        self.process.terminate()
        self.process.communicate(timeout=5)

    def request(self, request):
        with socket.create_connection(("127.0.0.1", self.port), timeout=5) as client:
            client.sendall(request.encode() + b"\n")
            chunks = []
            while True:
                chunk = client.recv(65536)
                if not chunk:
                    break
                chunks.append(chunk)
            return b"".join(chunks).decode().rstrip("\n")

    def test_capability_does_not_read_clipboard(self):
        self.assertEqual(self.request("CLIPBOARD_CAPABILITY"), "OK CLIPBOARD_V2")
        self.assertFalse(self.log.exists())

    def test_capability_preserves_read_support_without_pbcopy(self):
        (self.bin / "pbcopy").unlink()
        self.assertEqual(self.request("CLIPBOARD_CAPABILITY"), "OK CLIPBOARD_V1")
        self.assertFalse(self.log.exists())

    def test_capability_reports_missing_tools_without_reading(self):
        (self.bin / "pbpaste").unlink()
        self.assertEqual(
            self.request("CLIPBOARD_CAPABILITY"), "ERROR CLIPBOARD_UNAVAILABLE"
        )
        self.assertFalse(self.log.exists())

    def test_unicode_and_newlines_are_exactly_preserved(self):
        text = "C:/béstand 😄/file name.txt\r\nsecond\n\tline\n".encode()
        self.text.write_bytes(text)
        response = self.request("READ_CLIPBOARD")
        self.assertTrue(response.startswith("TEXT "), response)
        self.assertEqual(base64.b64decode(response[5:]), text)
        self.assertEqual(self.log.read_text(), "pngpaste\npbpaste\n")

    def test_image_has_priority_over_text(self):
        self.image.write_bytes(PNG)
        self.text.write_text("other")
        response = self.request("READ_CLIPBOARD")
        self.assertTrue(response.startswith("IMAGE "), response)
        self.assertEqual(base64.b64decode(response[6:]), PNG)
        self.assertEqual(self.image.with_suffix(".args").read_text(), "-")
        self.assertEqual(self.log.read_text(), "pngpaste\n")

    def test_empty_and_legacy_no_image(self):
        self.assertEqual(self.request("READ_CLIPBOARD"), "EMPTY")
        self.assertEqual(self.request("READ_CLIPBOARD_IMAGE"), "NO_IMAGE")

    def test_legacy_image(self):
        self.image.write_bytes(PNG)
        response = self.request("READ_CLIPBOARD_IMAGE")
        self.assertEqual(base64.b64decode(response[6:]), PNG)

    def test_oversized_image_is_rejected(self):
        self.image.write_bytes(PNG + b"x" * (10 * 1024 * 1024))
        self.assertTrue(
            self.request("READ_CLIPBOARD").startswith("ERROR CLIPBOARD_TOO_LARGE")
        )

    def test_oversized_text_is_rejected(self):
        self.text.write_bytes(b"x" * (10 * 1024 * 1024 + 1))
        self.assertTrue(
            self.request("READ_CLIPBOARD").startswith("ERROR CLIPBOARD_TOO_LARGE")
        )

    def test_maximum_size_text_is_accepted(self):
        text = b"x" * (10 * 1024 * 1024)
        self.text.write_bytes(text)
        response = self.request("READ_CLIPBOARD")
        self.assertTrue(response.startswith("TEXT "))
        self.assertEqual(base64.b64decode(response[5:]), text)

    def test_tools_share_a_two_second_deadline(self):
        delay = self.home / "delay"
        delay.mkdir()
        for tool in ("pngpaste", "pbpaste"):
            (delay / tool).write_text("1.3")
        started = time.monotonic()
        self.assertTrue(self.request("READ_CLIPBOARD").startswith("ERROR CLIPBOARD"))
        self.assertLess(time.monotonic() - started, 2.8)

    def test_malformed_request_never_reads_clipboard(self):
        self.assertEqual(self.request("READ_CLIPBOARD arbitrary"), "")
        self.assertFalse(self.log.exists())

    def test_write_unicode_and_newlines_reaches_pbcopy_as_utf8(self):
        text = "file béstand 😄\r\nsecond\n\tline\n".encode()
        encoded = base64.b64encode(text).decode()
        self.assertEqual(self.request("WRITE_CLIPBOARD " + encoded), "OK")
        self.assertEqual(self.text.read_bytes(), text)
        self.assertEqual(self.log.read_text(), "pbcopy\n")

    def test_write_empty_clipboard(self):
        for request in ("WRITE_CLIPBOARD", "WRITE_CLIPBOARD "):
            self.text.write_text("old value")
            self.assertEqual(self.request(request), "OK")
            self.assertEqual(self.text.read_bytes(), b"")

    def test_invalid_write_payload_does_not_change_clipboard(self):
        self.text.write_text("old value")
        for encoded in ("!bad", "ZA=", "ZE==", "====", "ZA== ", " ZA==", "/w=="):
            self.assertTrue(
                self.request("WRITE_CLIPBOARD " + encoded).startswith(
                    "ERROR CLIPBOARD_ENCODING"
                ),
                encoded,
            )
        self.assertEqual(self.text.read_text(), "old value")
        self.assertFalse(self.log.exists())

    def test_oversized_write_payload_does_not_change_clipboard(self):
        self.text.write_text("old value")
        encoded = base64.b64encode(b"x" * (10 * 1024 * 1024 + 1)).decode()
        self.assertTrue(
            self.request("WRITE_CLIPBOARD " + encoded).startswith(
                "ERROR CLIPBOARD_TOO_LARGE"
            )
        )
        self.assertEqual(self.text.read_text(), "old value")
        self.assertFalse(self.log.exists())

    def test_maximum_size_write_is_accepted(self):
        text = b"x" * (10 * 1024 * 1024)
        self.assertEqual(
            self.request("WRITE_CLIPBOARD " + base64.b64encode(text).decode()), "OK"
        )
        self.assertEqual(self.text.read_bytes(), text)

    def test_pbcopy_failure_is_not_acknowledged(self):
        self.text.write_text("old value")
        (self.home / "copy-result").write_text("1")
        self.assertTrue(
            self.request("WRITE_CLIPBOARD bmV3").startswith("ERROR CLIPBOARD_WRITE")
        )
        self.assertEqual(self.text.read_text(), "old value")

    def test_blocked_pbcopy_is_bounded_by_two_seconds(self):
        self.text.write_text("old value")
        delay = self.home / "delay"
        delay.mkdir()
        (delay / "pbcopy").write_text("3")
        text = b"x" * 65536
        started = time.monotonic()
        self.assertTrue(
            self.request(
                "WRITE_CLIPBOARD " + base64.b64encode(text).decode()
            ).startswith("ERROR CLIPBOARD_WRITE")
        )
        self.assertLess(time.monotonic() - started, 2.8)
        self.assertEqual(self.text.read_text(), "old value")


if __name__ == "__main__":
    unittest.main()
