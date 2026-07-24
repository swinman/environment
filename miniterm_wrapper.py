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

Fold noisy port families out of the picker with `--collapse` (repeat it, one
bucket each): "--collapse LABEL=REGEX", or a bare preset name -- "--collapse
ttyS" folds /dev/ttyS*.  These options are consumed here and not passed on to
miniterm; put them in your alias, e.g.:

    alias miniterm='python /path/to/miniterm_wrapper.py --collapse ttyS'

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
Matching the COLLAPSED_BUCKETS patterns against p.device alone is unambiguous
and actually keeps the ttyS ports out.

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
import select
import shutil
import string
import subprocess
import sys

import serial.tools.list_ports
from serial.tools.list_ports_common import ListPortInfo

# termios and tty are posix-only -- the single-keypress picker needs them for
# raw terminal access.  Where they are missing (Windows) or there is no
# controlling tty, the code falls back to the plain input() prompt.
try:
    import termios
    import tty
    RAW_TTY = True
except ImportError:
    RAW_TTY = False

# Key encodings returned by read_key(); a lone ESC is "\x1b", arrow keys are the
# full escape sequence, Ctrl-] (miniterm's exit char) is "\x1d".
KEY_UP, KEY_DOWN, KEY_RIGHT, KEY_LEFT = "\x1b[A", "\x1b[B", "\x1b[C", "\x1b[D"
KEY_ENTER = ("\r", "\n")
KEY_BACKSPACE = ("\x7f", "\b")
KEY_ESC = "\x1b"


def read_key(esc_delay: float = 0.04) -> str:
    """Read one keypress from stdin, which must already be in cbreak mode.

    A lone ESC comes back as "\x1b"; an escape sequence (arrow key) comes back
    whole.  They share the ESC prefix, so a short select() timeout after ESC is
    what tells a bare ESC from the start of a sequence -- a plain read-one-key
    call cannot, since both begin with ESC.
    """
    fd = sys.stdin.fileno()
    ch = os.read(fd, 1).decode("latin-1", "ignore")
    if ch != "\x1b":
        return ch
    seq = ch
    while len(seq) < 5 and select.select([fd], [], [], esc_delay)[0]:
        seq += os.read(fd, 1).decode("latin-1", "ignore")
    return seq

# Ordered buckets of ports to fold away, each shown as one collapsible line
# labelled with its name.  A port is claimed by the FIRST bucket whose pattern
# matches p.device (so a later, broader pattern never double-counts it), and a
# bucket only appears in the picker if it claimed at least one port.  Extend
# this list to fold new noisy port families out of the way -- the label travels
# with the pattern, so nothing hardcodes "/dev/ttyS".  Matched against p.device
# only (see the module docstring for why a grep-style "not ttyS" pattern fails).
COLLAPSED_BUCKETS = [
    # ttyS4 is this machine's one real 16550 UART (setserial shows the rest as
    # "unknown"), so exclude it from the fold -- it shows as an interesting port.
#    ("/dev/ttyS* (except ttyS4)", re.compile(r"^/dev/ttyS(?!4$)\d+$")),
]


def collapsed_bucket(device: str) -> int | None:
    """Index of the first COLLAPSED_BUCKETS entry matching `device`, else None
    (None meaning the port is interesting and shown normally)."""
    for i, (_, pattern) in enumerate(COLLAPSED_BUCKETS):
        if pattern.match(device):
            return i
    return None


# Bare `--collapse <name>` presets, so the common folds need no regex.
COLLAPSE_PRESETS = {
    "ttyS": ("/dev/ttyS*", re.compile(r"^/dev/ttyS\d+$")),
}


def parse_bucket(spec: str) -> tuple[str, "re.Pattern[str]"]:
    """Turn a --collapse value into a (label, compiled pattern) bucket rule.

    "LABEL=REGEX" -> that label and regex; a bare preset name (e.g. "ttyS") ->
    its built-in rule; anything else -> a bare regex (label = the regex).
    """
    if "=" in spec:
        label, _, pattern = spec.partition("=")
        return (label, re.compile(pattern))
    if spec in COLLAPSE_PRESETS:
        return COLLAPSE_PRESETS[spec]
    return (spec, re.compile(spec))


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
    """Sort key so ttyS9 sorts before ttyS10, shown ports ahead of collapsed."""
    dev = port.device
    collapsed = collapsed_bucket(dev) is not None
    nums = [int(n) for n in re.findall(r"\d+", dev)]
    return (collapsed, re.sub(r"\d+", "", dev), nums)


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


def render(interesting: list[ListPortInfo], buckets: list["Bucket"],
           show_all: bool) -> list[str]:
    """Print the menu; return the ordered device list matching the indices.
    Fallback (non-tty) path: `show_all` expands every bucket at once."""
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

    for label, ports in buckets:
        if show_all:
            print(f"\n  {MUTED}{label}{RESET}")
            for port in ports:
                idx = len(ordered) + 1
                ordered.append(port.device)
                print(f"  {MUTED}{idx:2d}  {port.device}{RESET}")
        else:
            # Reserve the numbers while collapsed so an index still resolves.
            ordered.extend(port.device for port in ports)
            print(f"\n  {MUTED}[ {len(ports)} {label} ports hidden"
                  f" -- 's' to show ]{RESET}")

    if not interesting and not buckets:
        print(f"\n  {MUTED}(no serial ports found){RESET}")
    return ordered


Bucket = tuple[str, list[ListPortInfo]]     # (label, ports) collapse group


def scan_ports() -> tuple[list[ListPortInfo], list[Bucket]]:
    """Return (interesting, buckets) in the order the picker shows.

    Interesting ports come first, then each non-empty COLLAPSED_BUCKETS group
    (as (label, ports)) in order.  The picker's index numbers -- and the
    `miniterm <n>` shortcut -- run straight down interesting ports then every
    bucket's ports.
    """
    ports = sorted(serial.tools.list_ports.comports(), key=natural_key)
    interesting: list[ListPortInfo] = []
    grouped: list[list[ListPortInfo]] = [[] for _ in COLLAPSED_BUCKETS]
    for port in ports:
        bi = collapsed_bucket(port.device)
        if bi is None:
            interesting.append(port)
        else:
            grouped[bi].append(port)
    buckets = [(COLLAPSED_BUCKETS[i][0], grouped[i])
               for i in range(len(COLLAPSED_BUCKETS)) if grouped[i]]
    return interesting, buckets


def ordered_devices(interesting: list[ListPortInfo],
                    buckets: list[Bucket]) -> list[str]:
    """Flat device-path list in picker/number order: interesting then buckets."""
    devices = [p.device for p in interesting]
    for _, ports in buckets:
        devices += [p.device for p in ports]
    return devices


def choose() -> str | None:
    """Return a chosen device path, or None to abort.

    Uses the single-keypress interactive picker on a posix terminal; otherwise
    falls back to the input() prompt.
    """
    interesting, buckets = scan_ports()
    if RAW_TTY and sys.stdin.isatty() and sys.stdout.isatty():
        return choose_interactive(interesting, buckets)
    return choose_prompt(interesting, buckets)


def choose_prompt(interesting: list[ListPortInfo],
                  buckets: list["Bucket"]) -> str | None:
    """Fallback picker: type an index or full port name, Enter to confirm."""
    show_all = not interesting  # nothing else to show -> expand right away

    while True:
        ordered = render(interesting, buckets, show_all)
        prompt = ("\n--- Enter port index or full name"
                  + ("" if show_all or not buckets else ", 's' to show hidden")
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
        if reply.lower() == "s" and buckets and not show_all:
            show_all = True
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


# --- single-keypress interactive picker (used on a posix terminal) ---

# Each row is (kind, number, port, bucket):
#   kind    "quit" | "port" | "hidden" | "expander"
#   number  display index for quit/port/hidden; -1 for an expander
#   port    ListPortInfo for "port"/"hidden", else None
#   bucket  bucket index for "hidden"/"expander", else None
MenuItem = tuple[str, int, ListPortInfo | None, int | None]


def menu_items(interesting: list[ListPortInfo], buckets: list["Bucket"],
               expanded: set[int]) -> list[MenuItem]:
    """Flat list of selectable rows.

    Numbering runs down interesting ports then every bucket's ports (matching
    scan_ports() order) and stays fixed regardless of which buckets are open: a
    collapsed bucket still reserves its ports' numbers, so expanding it never
    renumbers anything.  A bucket in `expanded` shows its ports; otherwise it
    shows a single "expander" row.
    """
    items: list[MenuItem] = [("quit", 0, None, None)]
    number = 0
    for port in interesting:
        number += 1
        items.append(("port", number, port, None))
    for bi, (_, ports) in enumerate(buckets):
        if bi in expanded:
            for port in ports:
                number += 1
                items.append(("hidden", number, port, bi))
        else:
            number += len(ports)             # reserve numbers so expand is stable
            items.append(("expander", -1, None, bi))
    return items


def item_number(items: list[MenuItem], num: int) -> int | None:
    """Index of the selectable item whose display number is `num`, else None."""
    for i, (kind, number, _port, _bi) in enumerate(items):
        if number == num and kind in ("quit", "port", "hidden"):
            return i
    return None


def bucket_of_number(num: int, n_interesting: int,
                     buckets: list["Bucket"]) -> int | None:
    """Which bucket the port numbered `num` belongs to (None if interesting or
    out of range) -- used to auto-expand the right bucket on a typed jump."""
    lo = n_interesting
    for bi, (_, ports) in enumerate(buckets):
        if lo < num <= lo + len(ports):
            return bi
        lo += len(ports)
    return None


def item_at(items: list[MenuItem], kind: str, bi: int) -> int | None:
    """Index of the first item of the given kind belonging to bucket `bi`."""
    for i, (k, _n, _p, b) in enumerate(items):
        if k == kind and b == bi:
            return i
    return None


def typed_for(item: MenuItem) -> str:
    """Number-field text matching a highlighted item ("" for the expander)."""
    kind, number, _port, _bi = item
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
    The expander is rendered by build_frame, which has the bucket label/count.
    """
    kind, number, port, _bi = item
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
        f"{MUTED}j/k move   digits jump   l/s/Enter select   q/Esc quit{RESET}",
        f"{BOLD}--- port #: {RESET}{typed}_",
    ]


def build_frame(items: list[MenuItem], sel: int, typed: str,
                buckets: list["Bucket"], rows: int) -> list[str]:
    """Assemble one on-screen frame: a pinned title, a single scrolling list of
    ALL options (quit, interesting ports, per-bucket collapse lines / ports)
    that follows the selection, and the pinned prompt foot -- kept within the
    terminal height so the foot never scrolls off.
    """
    usable = max(1, rows - 1)
    title = f"{BOLD}Serial ports{RESET}"
    foot = prompt_lines(typed)

    body: list[str] = []                     # the scrolling option rows
    focus = 0                                # body index of the selected row
    port_rows: list[int] = []                # body index of each port's main row
    prev_kind = None
    for i, (kind, _number, _port, bi) in enumerate(items):
        # Blank line between entries, but keep a bucket's ports block tight.
        if not (kind == "hidden" and prev_kind == "hidden"):
            body.append("")
        prev_kind = kind
        if i == sel:
            focus = len(body)
        if kind in ("port", "hidden"):       # counted by the scroll markers
            port_rows.append(len(body))
        if kind == "expander":
            label, ports = buckets[bi]
            text = f"[ {len(ports)} {label} ports hidden -- l/s or Enter ]"
            body.append(menu_row(i == sel, 0, text, MUTED, plain=True))
        else:
            body += item_lines(items[i], i == sel)

    any_expanded = any(kind == "hidden" for kind, _n, _p, _b in items)
    below_extra = ", h to collapse" if any_expanded else ""
    view_h = max(1, usable - 1 - len(foot))  # 1 line reserved for the title
    return [title] + window_rows(body, focus, view_h, port_rows, below_extra) + foot


def choose_interactive(interesting: list[ListPortInfo],
                       buckets: list["Bucket"]) -> str | None:
    """Single-keypress picker with a number field.  Arrows / j-k move the
    highlight and fill the field; digits jump (auto-expanding the right bucket);
    l/s/Enter (or Right) select the current row -- opening a port or expanding a
    collapse line; h/Left collapses the bucket you are in; q / 0 / Esc / Ctrl-]
    quit.
    """
    quit_keys = ("q", "Q", KEY_ESC, "\x1d")           # \x1d == Ctrl-]
    n_interesting = len(interesting)
    expanded: set[int] = set() if interesting else set(range(len(buckets)))
    sel = 0                                           # start on "quit"
    typed = ""
    drawn = 0                                          # lines in the last frame

    fd = sys.stdin.fileno()
    old_term = termios.tcgetattr(fd)
    tty.setcbreak(fd)                                 # unbuffered, no echo, keep Ctrl-C
    sys.stdout.write("\033[?25l")                     # hide cursor
    try:
        while True:
            items = menu_items(interesting, buckets, expanded)
            sel = max(0, min(sel, len(items) - 1))
            frame = build_frame(items, sel, typed, buckets,
                                shutil.get_terminal_size().lines)
            # Redraw in place: step back over the previous frame and clear from
            # there down, leaving scrollback above the picker untouched.
            if drawn:
                sys.stdout.write(f"\033[{drawn}A")
            sys.stdout.write("\033[0J" + "\n".join(frame) + "\n")
            sys.stdout.flush()
            drawn = len(frame)

            try:
                press = read_key()
            except KeyboardInterrupt:
                return None

            if press in quit_keys:
                return None
            elif press in (KEY_UP, "k"):
                sel = max(0, sel - 1)
                typed = typed_for(items[sel])
            elif press in (KEY_DOWN, "j"):
                sel = min(len(items) - 1, sel + 1)
                typed = typed_for(items[sel])
            elif press in (KEY_LEFT, "h") and items[sel][0] == "hidden":
                bi = items[sel][3]                    # collapse the bucket we are in
                expanded.discard(bi)
                items = menu_items(interesting, buckets, expanded)
                back = item_at(items, "expander", bi)
                if back is not None:
                    sel = back
                typed = ""
            elif press.isdigit():
                typed = (typed + press).lstrip("0") or "0"
                num = int(typed)
                bi = bucket_of_number(num, n_interesting, buckets)
                if bi is not None and bi not in expanded:
                    expanded.add(bi)                  # jump auto-expands its bucket
                    items = menu_items(interesting, buckets, expanded)
                found = item_number(items, num)
                if found is not None:
                    sel = found
            elif press in KEY_BACKSPACE:
                typed = typed[:-1]
                if typed:
                    found = item_number(items, int(typed))
                    if found is not None:
                        sel = found
            elif press in (*KEY_ENTER, KEY_RIGHT, "l", "s"):
                target = sel
                if typed:
                    found = item_number(items, int(typed))
                    if found is None:
                        continue                      # typed number out of range
                    target = found
                kind, _num, port, bi = items[target]
                if kind == "quit":
                    return None
                if kind == "expander":
                    expanded.add(bi)
                    items = menu_items(interesting, buckets, expanded)
                    first = item_at(items, "hidden", bi)
                    if first is not None:
                        sel = first
                        typed = typed_for(items[sel])
                elif port is not None:
                    return port.device
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old_term)
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
    # Pull our own --collapse options out first (repeatable; one bucket each,
    # so they never swallow the port), leaving the rest for miniterm.  Given
    # any, they replace the module-level COLLAPSED_BUCKETS default.
    parser = argparse.ArgumentParser(add_help=False)
    parser.add_argument("--collapse", action="append", default=[], metavar="SPEC")
    opts, args = parser.parse_known_args()
    if opts.collapse:
        global COLLAPSED_BUCKETS
        try:
            COLLAPSED_BUCKETS = [parse_bucket(spec) for spec in opts.collapse]
        except re.error as exc:
            print(f"{WARN}bad --collapse regex: {exc}{RESET}")
            return 2

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
        devices = ordered_devices(*scan_ports())
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
