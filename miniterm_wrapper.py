#!/usr/bin/env python
"""Front end for pyserial's miniterm with a nicer port picker.

Replaces miniterm's plain "--- Enter port index or full name:" prompt with a
listing that shows the useful details (product, manufacturer, VID:PID, USB
location) for the ports you actually care about, while collapsing the pile of
on-board /dev/ttyS* ports behind a single line you can expand on demand.

Any arguments given to this script are forwarded to miniterm after the chosen
port, so `miniterm_wrapper.py 115200 --rtscts` works as expected.

Why the hiding is done by matching p.device directly rather than a "not ttyS"
regex through list_ports.grep(): pyserial's grep (and miniterm's own picker)
count a port as a match if the regex hits ANY of its fields -- device, name, OR
hwid.  A negative pattern like ^(?!.*ttyS).*$ therefore only excludes on the
device field; a ttyS port's description/hwid are "n/a", which contain no
"ttyS", so the OR matches those fields and the port slips back into the list.
Matching HIDDEN_PORT_RE against p.device alone is unambiguous and actually
keeps the ttyS ports out.
"""

import os
import re
import string
import subprocess
import sys

import serial.tools.list_ports
from serial.tools.list_ports_common import ListPortInfo

# Device paths matching this are the noisy on-board ttyS* UARTs: collapsed
# behind one line until the user expands them.  Matched against p.device only
# (see the module docstring for why a grep-style "not ttyS" pattern fails).
HIDDEN_PORT_RE = re.compile(r"/dev/ttyS\d+$")

# Passed to miniterm on every launch (matches the `miniterm -e` alias).
MINITERM_DEFAULT_ARGS = ["-e"]

# ANSI styles, disabled automatically when stdout is not a terminal.  Kept to
# bold + the bright base colours (no faint/dim), which stay legible on both
# light and dark terminal themes -- tweak these if your palette differs.
#   DEVICE : the port path            LABEL : field names
#   VALUE  : field values            ACCENT : serial number (matters most)
if sys.stdout.isatty():
    BOLD = "\033[1m"
    DEVICE = "\033[1;32m"   # bold green
    LABEL = "\033[36m"      # cyan
    VALUE = "\033[0m"       # terminal default
    ACCENT = "\033[1;33m"   # bold yellow
    MUTED = "\033[90m"      # bright black / grey
    WARN = "\033[33m"       # yellow
    RESET = "\033[0m"
else:
    BOLD = DEVICE = LABEL = VALUE = ACCENT = MUTED = WARN = RESET = ""


def natural_key(port: ListPortInfo) -> tuple[bool, str, list[int]]:
    """Sort key so ttyS9 sorts before ttyS10, shown ports ahead of hidden."""
    dev = port.device
    hidden = bool(HIDDEN_PORT_RE.match(dev))
    nums = [int(n) for n in re.findall(r"\d+", dev)]
    return (hidden, re.sub(r"\d+", "", dev), nums)


def printable(text: str | None) -> str:
    """Strip the unprintable junk some devices stuff into serial_number."""
    if not text:
        return ""
    kept = "".join(c for c in text if c in string.printable and c not in "\r\n\t")
    return kept.strip()


def serial_field(port: ListPortInfo) -> tuple[str | None, bool]:
    """Return (value, is_real) for the serial number.

    The serial number is usually important, so it is never silently dropped:
    if the device reports one that is all 0xFF (or otherwise non-printable)
    that is called out as unset rather than omitted.  is_real is True only for
    an actual, printable serial.
    """
    sn = port.serial_number
    if sn is None:
        return None, False
    clean = printable(sn)
    if clean:
        return clean, True
    if all(ch == "\xff" for ch in sn):
        return "<unset -- all 0xFF>", False
    return "<unset -- non-printable>", False


def describe(port: ListPortInfo) -> list[tuple[str, str, bool]]:
    """Yield (header, value, is_serial) detail rows for an interesting port."""
    rows = []
    product = printable(port.product) or printable(port.description)
    if product and product != "n/a":
        rows.append(("product", product, False))

    sn_value, _ = serial_field(port)
    if sn_value is not None:
        rows.append(("serial", sn_value, True))

    if port.vid is not None and port.pid is not None:
        rows.append(("vid:pid", f"{port.vid:04X}:{port.pid:04X}", False))
    mfg = printable(port.manufacturer)
    if mfg:
        rows.append(("vendor", mfg, False))
    if port.location:
        rows.append(("usb path", port.location, False))
    return rows


def render(interesting: list[ListPortInfo], hidden: list[ListPortInfo],
           show_hidden: bool) -> list[str]:
    """Print the menu; return the ordered device list matching the indices."""
    print()
    print(f"{BOLD}Serial ports{RESET}")

    ordered = []
    for port in interesting:
        idx = len(ordered) + 1
        ordered.append(port.device)
        print(f"\n  {BOLD}{idx:2d}{RESET}  {DEVICE}{port.device}{RESET}")
        rows = describe(port)
        width = max((len(h) for h, _, _ in rows), default=0)
        for header, value, is_serial in rows:
            colour = ACCENT if is_serial else VALUE
            print(f"        {LABEL}{header:>{width}}{RESET} : {colour}{value}{RESET}")

    if hidden and not show_hidden:
        print(f"\n  {MUTED}[ {len(hidden)} /dev/ttyS* ports hidden"
              f" -- type 's' to show ]{RESET}")
    elif hidden:
        print(f"\n  {MUTED}on-board serial ports (ttyS*){RESET}")
        for port in hidden:
            idx = len(ordered) + 1
            ordered.append(port.device)
            print(f"  {MUTED}{idx:2d}  {port.device}{RESET}")

    if not interesting and not hidden:
        print(f"\n  {MUTED}(no serial ports found){RESET}")
    return ordered


def choose() -> str | None:
    """Interactive picker. Returns a device path, or None to abort."""
    ports = sorted(serial.tools.list_ports.comports(), key=natural_key)
    interesting = [p for p in ports if not HIDDEN_PORT_RE.match(p.device)]
    hidden = [p for p in ports if HIDDEN_PORT_RE.match(p.device)]
    show_hidden = not interesting  # nothing else to show -> expand right away

    while True:
        ordered = render(interesting, hidden, show_hidden)
        prompt = ("\n--- Enter port index or full name"
                  + ("" if show_hidden or not hidden else ", 's' to show ttyS*")
                  + ", 'q' to quit: ")
        try:
            reply = input(prompt).strip()
        except (EOFError, KeyboardInterrupt):
            print()
            return None

        if not reply:
            continue
        if reply.lower() in ("q", "quit"):
            return None
        if reply.lower() == "s" and hidden and not show_hidden:
            show_hidden = True
            continue
        if reply.isdigit():
            i = int(reply)
            if 1 <= i <= len(ordered):
                return ordered[i - 1]
            print(f"{WARN}  index out of range{RESET}")
            continue
        # Treat anything else as a full port name (allow bare tty names too).
        if os.path.exists(reply):
            return reply
        if os.path.exists("/dev/" + reply):
            return "/dev/" + reply
        print(f"{WARN}  no such port: {reply}{RESET}")


def main() -> int:
    port = choose()
    if port is None:
        return 1
    cmd = ([sys.executable, "-m", "serial.tools.miniterm"]
           + MINITERM_DEFAULT_ARGS + [port] + sys.argv[1:])
    print(f"{MUTED}>>> {' '.join(cmd)}{RESET}")
    return subprocess.call(cmd)


if __name__ == "__main__":
    sys.exit(main())
