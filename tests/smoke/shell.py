"""Run the real login shell with a terminal, as its prompt/plugins expect."""

import errno
import os
from pathlib import Path
import pty
import re
import select
import signal
import time

pid, terminal = pty.fork()
if pid == 0:
    os.chdir(Path.home())
    os.execvp("zsh", ["zsh", "-lic", 'source "$DOTFILES_TEST_REPOSITORY/tests/smoke/zsh.zsh"'])

output = bytearray()
deadline = time.monotonic() + 120
try:
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            os.killpg(pid, signal.SIGKILL)
            raise TimeoutError("Login shell smoke test timed out")
        if select.select([terminal], [], [], min(remaining, 1))[0]:
            try:
                chunk = os.read(terminal, 65536)
            except OSError as error:
                if error.errno != errno.EIO:
                    raise
                break
            if not chunk:
                break
            output.extend(chunk)
finally:
    os.close(terminal)
    _, status = os.waitpid(pid, 0)
    text = output.decode(errors="replace")
    print(text, end="")

assert os.waitstatus_to_exitcode(status) == 0, "Login shell smoke test failed"
# Startup errors often do not affect Zsh's final exit status. Reject unexpected
# output as well; allow terminal styling emitted by the prompt.
plain = re.sub(r"\x1b\[[0-?]*[ -/]*[@-~]", "", text).strip()
assert plain == "Shell smoke tests passed", f"Unexpected shell startup output: {plain!r}"
