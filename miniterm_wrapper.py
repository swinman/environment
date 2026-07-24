#!/usr/bin/env python
"""Front end for pyserial's miniterm with a nicer port picker.

Setup: this is a standalone script (needs pyserial).  To use it as your
`miniterm` command, add an alias to your shell rc (~/.bashrc, ~/.bash_aliases,
~/.zshrc, ...):

    alias miniterm='python /path/to/miniterm_wrapper.py'

Run it directly as `python miniterm_wrapper.py [miniterm args...]`.  Naming a
port (`... /dev/ttyACM0`), a list number 1-3 (`... 1` opens the first device
the picker would list), or passing -h/--help skips the picker;
otherwise the picker runs and its choice becomes the port.  Any other arguments
pass through to miniterm (e.g. a trailing baud rate: `... /dev/ttyACM0 115200`).

Replaces miniterm's plain "--- Enter port index or full name:" prompt with a
listing that shows the useful details (product, manufacturer, VID:PID, USB
location) for the ports you actually care about, while collapsing the pile of
on-board /dev/ttyS* ports behind a single line you can expand on demand.

Why the hiding is done by matching p.device directly rather than a "not ttyS"
regex through list_ports.grep(): pyserial's grep (and miniterm's own picker)
count a port as a match if the regex hits ANY of its fields -- device, name, OR
hwid.  A negative pattern like ^(?!.*ttyS).*$ therefore only excludes on the
device field; a ttyS port's description/hwid are "n/a", which contain no
"ttyS", so the OR matches those fields and the port slips back into the list.
Matching HIDDEN_PORT_RE against p.device alone is unambiguous and actually
keeps the ttyS ports out.

The product/vendor/serial shown for each port come straight from the device's
own USB string descriptors (pyserial reads them from sysfs, populated by the
kernel from what the firmware reports).  They are NOT the names `lsusb` prints
by default, which come from the usb.ids database looked up by VID:PID.  So a
device whose firmware reports different strings than usb.ids lists for its
VID:PID reads differently here than in lsusb's default output; `lsusb -v` shows
both (idVendor/idProduct from usb.ids vs iManufacturer/iProduct descriptors).
"""

import argparse
import contextlib
import io
import os
import re
import shutil
import string
import subprocess
import sys

import serial.tools.list_ports
from serial.tools.list_ports_common import ListPortInfo

# Optional: enables the single-keypress interactive picker (arrows / j-k, no
# Enter).  Absent -> the code falls back to the plain input() prompt, so this
# stays a soft dependency.
try:
    import readchar
except ImportError:
    readchar = None

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
# SGR code reference (the "\033[<n>m" numbers below):
#   https://en.wikipedia.org/wiki/ANSI_escape_code#Select_Graphic_Rendition_parameters
if sys.stdout.isatty():
    BOLD = "\033[1m"
    DEVICE = "\033[1;32m"   # bold green
    LABEL = "\033[36m"      # cyan
    VALUE = "\033[0m"       # terminal default
    ACCENT = "\033[1;33m"   # bold yellow
    MUTED = "\033[37m"      # white / light grey (dimmer than default, still legible)
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


def scan_ports() -> tuple[list[ListPortInfo], list[ListPortInfo]]:
    """Return (interesting, hidden) port lists in the order the picker shows.

    Interesting ports come first, then the on-board ttyS* ports; the picker's
    index numbers -- and the `miniterm <n>` shortcut -- run straight down this
    combined order.
    """
    ports = sorted(serial.tools.list_ports.comports(), key=natural_key)
    interesting = [p for p in ports if not HIDDEN_PORT_RE.match(p.device)]
    hidden = [p for p in ports if HIDDEN_PORT_RE.match(p.device)]
    return interesting, hidden


def choose() -> str | None:
    """Return a chosen device path, or None to abort.

    Uses the single-keypress interactive picker when readchar is importable and
    both streams are a terminal; otherwise falls back to the input() prompt.
    """
    interesting, hidden = scan_ports()
    if readchar is not None and sys.stdin.isatty() and sys.stdout.isatty():
        return choose_interactive(interesting, hidden)
    return choose_prompt(interesting, hidden)


def choose_prompt(interesting: list[ListPortInfo],
                  hidden: list[ListPortInfo]) -> str | None:
    """Fallback picker: type an index or full port name, Enter to confirm."""
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
        if reply.lower() in ("q", "quit", "0"):
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


# --- single-keypress interactive picker (used when readchar is available) ---

MenuItem = tuple[str, int, ListPortInfo | None]


def menu_items(interesting: list[ListPortInfo], hidden: list[ListPortInfo],
               expanded: bool) -> list[MenuItem]:
    """Flat list of selectable rows as (kind, number, port).

    kind is "quit", "port" (interesting, full detail), "hidden" (compact ttyS),
    or "expander" (the collapsed-ttyS line).  Numbering runs down the
    interesting ports then the hidden ports, matching scan_ports() order.
    """
    items: list[MenuItem] = [("quit", 0, None)]
    number = 0
    for port in interesting:
        number += 1
        items.append(("port", number, port))
    if hidden and not expanded:
        items.append(("expander", 0, None))
    elif hidden:
        for port in hidden:
            number += 1
            items.append(("hidden", number, port))
    return items


def item_number(items: list[MenuItem], num: int) -> int | None:
    """Index of the selectable item whose display number is `num`, else None."""
    for i, (kind, number, _) in enumerate(items):
        if number == num and kind in ("quit", "port", "hidden"):
            return i
    return None


def typed_for(item: MenuItem) -> str:
    """Number-field text matching a highlighted item ("" for the expander)."""
    kind, number, _ = item
    return str(number) if kind in ("quit", "port", "hidden") else ""


def menu_row(selected: bool, number: int, body: str, colour: str,
             plain: bool = False) -> str:
    """One main row: ">>> " gutter + bold device when selected, otherwise the
    normal colour so the listing stays readable as a device inventory, not just
    a selector.  Gutters are equal width so rows line up either way.
    """
    core = body if plain else f"{number:>2}  {body}"
    if selected:
        return f">>> {BOLD}{core}{RESET}"
    return f"    {colour}{core}{RESET}"


def item_lines(item: MenuItem, selected: bool) -> list[str]:
    """Lines for one item: the main row plus detail rows for interesting ports.
    The expander is rendered by build_frame, which has the hidden count.
    """
    kind, number, port = item
    if kind == "quit":
        return [menu_row(selected, 0, "quit", MUTED)]
    if kind == "hidden":
        return [menu_row(selected, number, port.device, MUTED)]
    if kind == "port":
        lines = [menu_row(selected, number, port.device, DEVICE)]
        rows = describe(port)
        width = max((len(h) for h, _, _ in rows), default=0)
        for header, value, is_serial in rows:
            colour = ACCENT if is_serial else VALUE
            lines.append(
                f"        {LABEL}{header:>{width}}{RESET} : {colour}{value}{RESET}")
        return lines
    return []


def window_rows(rows_list: list[str], focus: int, height: int,
                port_rows: list[int], below_extra: str = "") -> list[str]:
    """Slice `rows_list` to at most `height` lines keeping row index `focus` in
    view.  When content is scrolled, a "-- N more above/below --" marker line is
    added (its own line, not overlaying content) where N counts the *ports* (row
    indices in `port_rows`) scrolled out of view -- not raw lines.  `below_extra`
    (e.g. ", h to collapse") is appended to the below marker.
    """
    total = len(rows_list)
    if total <= height:
        return rows_list
    inner = max(1, height - 2)               # leave room for up to two markers
    start = max(0, min(focus - inner // 2, total - inner))
    end = start + inner
    above = sum(1 for r in port_rows if r < start)
    below = sum(1 for r in port_rows if r >= end)
    out = []
    if start > 0 and above:
        out.append(f"    {MUTED}-- {above} more above --{RESET}")
    out += rows_list[start:end]
    if end < total and below:
        out.append(f"    {MUTED}-- {below} more below{below_extra} --{RESET}")
    return out


def prompt_lines(typed: str) -> list[str]:
    """The pinned foot: a key hint and the number entry field."""
    return [
        "",
        f"{MUTED}j/k move   digits jump   Enter/l/s select   q quit{RESET}",
        f"{BOLD}--- port #: {RESET}{typed}_",
    ]


def build_frame(items: list[MenuItem], sel: int, typed: str, n_hidden: int,
                rows: int) -> list[str]:
    """Assemble one on-screen frame: a pinned title, a single scrolling list of
    ALL options (quit, interesting ports, ttyS*) that follows the selection,
    and the pinned prompt foot -- kept within the terminal height so the foot
    never scrolls off.
    """
    usable = max(1, rows - 1)
    title = f"{BOLD}Serial ports{RESET}"
    foot = prompt_lines(typed)

    body: list[str] = []                     # the scrolling option rows
    focus = 0                                # body index of the selected row
    port_rows: list[int] = []                # body index of each port's main row
    prev_kind = None
    for i, item in enumerate(items):
        kind = item[0]
        # Blank line between entries, but keep the ttyS* block tight.
        if not (kind == "hidden" and prev_kind == "hidden"):
            body.append("")
        prev_kind = kind
        if i == sel:
            focus = len(body)
        if kind in ("port", "hidden"):       # counted by the scroll markers
            port_rows.append(len(body))
        if kind == "expander":
            text = f"[ {n_hidden} /dev/ttyS* ports hidden -- Enter/l or s ]"
            body.append(menu_row(i == sel, 0, text, MUTED, plain=True))
        else:
            body += item_lines(item, i == sel)

    expanded = any(kind == "hidden" for kind, _, _ in items)
    below_extra = ", h to collapse" if expanded else ""
    view_h = max(1, usable - 1 - len(foot))  # 1 line reserved for the title
    return [title] + window_rows(body, focus, view_h, port_rows, below_extra) + foot


def choose_interactive(interesting: list[ListPortInfo],
                       hidden: list[ListPortInfo]) -> str | None:
    """Single-keypress picker with a number field.  Arrows / j-k move the
    highlight and fill the field; digits jump (auto-expanding ttyS* as needed);
    Enter or l/Right opens (or expands the ttyS* row); h/Left collapses; s
    expands; q / 0 / Esc / Ctrl-] quit.
    """
    key = readchar.key
    quit_keys = ("q", "Q", key.ESC, "\x1d")          # \x1d == Ctrl-]
    n_interesting = len(interesting)
    expanded = not interesting                        # nothing else -> expand now
    sel = 0                                           # start on "quit"
    typed = ""
    drawn = 0                                          # lines in the last frame

    sys.stdout.write("\033[?25l")                     # hide cursor
    try:
        while True:
            items = menu_items(interesting, hidden, expanded)
            sel = max(0, min(sel, len(items) - 1))
            frame = build_frame(items, sel, typed, len(hidden),
                                shutil.get_terminal_size().lines)
            # Redraw in place: step back over the previous frame and clear from
            # there down, leaving scrollback above the picker untouched.
            if drawn:
                sys.stdout.write(f"\033[{drawn}A")
            sys.stdout.write("\033[0J" + "\n".join(frame) + "\n")
            sys.stdout.flush()
            drawn = len(frame)

            try:
                press = readchar.readkey()
            except KeyboardInterrupt:
                return None

            if press in quit_keys:
                return None
            elif press in (key.UP, "k"):
                sel = max(0, sel - 1)
                typed = typed_for(items[sel])
            elif press in (key.DOWN, "j"):
                sel = min(len(items) - 1, sel + 1)
                typed = typed_for(items[sel])
            elif press in (key.LEFT, "h") and expanded and hidden:
                expanded = False
                sel = n_interesting + 1               # back onto the expander
                typed = ""
            elif press.isdigit():
                typed = (typed + press).lstrip("0") or "0"
                num = int(typed)
                if not expanded and hidden and num > n_interesting:
                    expanded = True
                    items = menu_items(interesting, hidden, expanded)
                found = item_number(items, num)
                if found is not None:
                    sel = found
            elif press in (key.BACKSPACE, "\x7f", "\b"):
                typed = typed[:-1]
                if typed:
                    found = item_number(items, int(typed))
                    if found is not None:
                        sel = found
            elif press in (key.ENTER, "\r", "\n", key.RIGHT, "l", "s"):
                target = sel
                if typed:
                    found = item_number(items, int(typed))
                    if found is None:
                        continue                      # typed number out of range
                    target = found
                kind, _, port = items[target]
                if kind == "quit":
                    return None
                if kind == "expander":
                    expanded = True
                    sel = n_interesting + 1
                    typed = str(n_interesting + 1)
                elif port is not None:
                    return port.device
    finally:
        sys.stdout.write("\033[?25h")                 # restore cursor
        sys.stdout.flush()
        print()


def port_given(args: list[str]) -> bool:
    """True if the command line already names a port, so the picker is skipped.

    Uses argparse's parse_known_args() to ignore every miniterm flag and the
    baud rate and pull out just the port positional.  parse_known_args cannot
    tell that an *unrecognized* option takes a value, so the value-taking
    options are declared here -- otherwise `--rts 1` would hand "1" to the port
    positional.  Bare flags left undeclared are ignored harmlessly.

    A lone "-" is miniterm's own "list the ports" request, so it counts as no
    port and the picker still runs.
    """
    parser = argparse.ArgumentParser(add_help=False)
    for opt in ("--parity", "--rts", "--dtr", "--encoding", "--eol",
                "--exit-char", "--menu-char"):
        parser.add_argument(opt)
    parser.add_argument("-f", "--filter", action="append")
    parser.add_argument("port", nargs="?")
    try:
        # parse_known_args exits on a malformed option (e.g. a value option
        # with no value); let miniterm be the one to report that, and just
        # fall back to the picker here.
        with contextlib.redirect_stderr(io.StringIO()):
            namespace, _ = parser.parse_known_args(args)
    except SystemExit:
        return False
    return namespace.port not in (None, "-")


def main() -> int:
    args = sys.argv[1:]
    # Bare "python" (not sys.executable's full path) keeps the echoed command
    # short; PATH resolves it to the same interpreter that launched this script.
    base = ["python", "-m", "serial.tools.miniterm"]

    # -h/--help: let miniterm print its own help, no picker.
    if "-h" in args or "--help" in args:
        return subprocess.call(base + args)

    # A digit 1-3 as the first argument selects that entry from the port list
    # (as numbered by the picker), skipping the prompt: `miniterm 1` opens the
    # first device.  1-3 covers every realistic device count; 0 and 4+ fall
    # through so miniterm reports them as an unknown port, and bigger counts
    # are a job for the picker.  Resolve to a device path here, then fall
    # through to the normal "port named on the command line" handling.
    if args and re.fullmatch(r"[1-3]", args[0]):
        interesting, hidden = scan_ports()
        devices = [p.device for p in interesting] + [p.device for p in hidden]
        index = int(args[0])
        if not 1 <= index <= len(devices):
            print(f"{WARN}no port #{index} (found {len(devices)}){RESET}")
            return 1
        args = [devices[index - 1]] + args[1:]

    if port_given(args):
        # A port was named on the command line -- hand off untouched.
        cmd = base + MINITERM_DEFAULT_ARGS + args
    else:
        port = choose()
        if port is None:
            return 1
        rest = [a for a in args if a != "-"]    # drop miniterm's list request
        cmd = base + MINITERM_DEFAULT_ARGS + [port] + rest

    print(f"{MUTED}>>> {' '.join(cmd)}{RESET}\n")
    return subprocess.call(cmd)


if __name__ == "__main__":
    sys.exit(main())
