---
name: linux-screen-capture
description: Capture desktop screenshots on Linux using ffmpeg x11grab, unlock locked sessions, and deliver to the user via messaging platforms.
trigger: User asks for a screenshot of the desktop/monitor, screen capture, "lihat desktop" in remote-access scenarios, or says "Ss" (user shorthand for screenshot).
---

# Linux Screen Capture

Capture the desktop/monitor output on a Linux machine and deliver it to the user — useful when the user is away from the PC (remote access) and wants to see what's on screen.

## Prerequisites

- **ffmpeg** with x11grab support (usually pre-installed; `apt install ffmpeg` if missing)
- **X11 display** running (verify via `ls /tmp/.X11-unix/`)
- User must be logged into a graphical session (check with `who` or `loginctl list-sessions`)

## User Preferences

This skill is personalized:

- **"Ss"** — the user's shorthand for "screenshot". When they say "Ss", take a screenshot immediately without asking for confirmation. No need to clarify or confirm — just capture and deliver.

## Steps

### 1. Check X11 display availability

```bash
ls /tmp/.X11-unix/        # shows X sockets (e.g. X0)
loginctl list-sessions     # shows active sessions
who -u                     # shows which user is on :0
```

### 2. Set the DISPLAY variable

The DISPLAY env var is often unset in Hermes' environment. Set it explicitly:

```bash
export DISPLAY=:0
```

### 3. Capture screenshot with ffmpeg x11grab

```bash
export DISPLAY=:0 && ffmpeg -f x11grab -video_size 1920x1080 -i :0 -frames 1 -update 1 -y ~/.hermes/image_cache/screenshot.jpg
```

Options explained:
- `-f x11grab` — X11 screen capture input format
- `-video_size 1920x1080` — resolution (adjust to match monitor: `xdpyinfo | grep dimensions` to detect)
- `-i :0` — display :0 (use `:0.0+10,20` to capture a specific screen area at offset)
- `-frames 1` — capture exactly one frame
- `-update 1` — overwrite the output file for single-image mode (REQUIRED)
- `-y` — overwrite without asking

**Check file size** as a quick quality indicator:
- 100KB+ at 1920×1080 → likely good (has content)
- 10–50KB → likely dim or mostly uniform background
- Under 10KB → likely black/empty screen (locked session or monitor off)

### 4. Deliver to user

File is already saved to `~/.hermes/image_cache/`, which is a Hermes-allowed media root. Send directly:

```yaml
send_message(target="telegram", message="MEDIA:/home/who/.hermes/image_cache/screenshot.jpg")
```

Or inline in response:
```
MEDIA:/home/who/.hermes/image_cache/screenshot.jpg
```

### 5. Cleanup (optional)

```bash
rm ~/.hermes/image_cache/screenshot.jpg
```

## Unlocking a Locked Desktop

If the screenshot shows a black/lock screen (file under ~10KB), the desktop is likely locked. Unlock it:

### 5a. Check lock status

```bash
loginctl show-session <SESSION_ID> -p LockedHint   # returns LockedHint=yes or LockedHint=no
```

Find the session ID from `loginctl list-sessions` (look for `seat0`, `tty2` or `tty7`).

### 5b. Try quick unlock (often insufficient for GDM)

```bash
loginctl unlock-session <SESSION_ID>   # e.g. unlock-session 2
```

Then check LockedHint. If still `yes`, GDM's lock screen bypasses PAM — proceed to 5c.

### 5c. Fallback: Send password keystrokes via Python + pynput (GDM workaround)

GDM (GNOME Display Manager) lock screens do NOT respond to `loginctl unlock-session` alone. You must simulate actual keystrokes. `xdotool` is often not installed and `sudo` may be unavailable — use Python instead.

**Step 1 — Install pynput** (pip may need bootstrapping first):

```bash
python3 -m ensurepip   # only if pip is missing
python3 -m pip install pynput
```

**Step 2 — Send password keystrokes:**

```python
from pynput.keyboard import Key, Controller
import time

keyboard = Controller()
password = "USER_PASSWORD_HERE"   # ask user for it

# Type password
for char in password:
    keyboard.press(char)
    time.sleep(0.05)
    keyboard.release(char)
    time.sleep(0.05)

# Press Enter
keyboard.press(Key.enter)
time.sleep(0.05)
keyboard.release(Key.enter)
```

Run via terminal:
```bash
DISPLAY=:0 python3 -c "
from pynput.keyboard import Key, Controller
import time
k = Controller()
for c in 'PASSWORD':
    k.press(c); time.sleep(0.05); k.release(c); time.sleep(0.05)
k.press(Key.enter); time.sleep(0.05); k.release(Key.enter)
print('Unlock attempt sent')
"
```

Always **ask the user for their password** (via `clarify` tool) — never guess or store it.

### 5d. Verify unlock

```bash
loginctl show-session <SESSION_ID> -p LockedHint   # should return LockedHint=no
```

Then re-run the screenshot capture from step 3.

## Pitfalls

| Pitfall | Solution |
|---------|----------|
| **DISPLAY not set** | `export DISPLAY=:0` before ffmpeg — Hermes' env often lacks it |
| **"Could not open display"** | Ensure X server is running (`ls /tmp/.X11-unix/`) and DISPLAY is correct |
| **Screenshot all black** (also < 10KB) | Desktop is likely locked — attempt unlock via loginctl, then fallback to pynput keystroke method (see section 5) |
| **Screenshot dim / low file size** | Monitor may be off or in power-save mode — check if PC is awake |
| **No `/tmp/.X11-unix/` at all** | No X server running — PC may be on console-only mode or Wayland. For Wayland, try `wlr-screenshot`, `grim`, or `gnome-screenshot -i` |
| **ffmpeg: Unsupported pixel format** | Try lower resolution or add `-pix_fmt yuv420p` to the output options |
| **`xdotool` not installed / `sudo` unavailable** | Use Python `pynput` library as fallback for mouse/keyboard simulation. Install via `python3 -m pip install pynput` |
| **File size drop after first screenshot** | Monitor may have gone to sleep — move mouse before capture. If `xdotool` is not installed (common), use Python: `DISPLAY=:0 python3 -c \"from pynput.mouse import Controller; import time; Controller().move(100,100); time.sleep(0.5)\"` (install pynput first: `python3 -m pip install pynput`) |
| **`loginctl unlock-session` doesn't work** | GDM bypasses PAM — `loginctl unlock-session` alone is insufficient. Use pynput keystroke method (section 5c) to type the user's password |
| **MEDIA tag sent but image doesn't appear** | File path not in an allowed Hermes media root. Use `~/.hermes/image_cache/` (see webcam-capture skill for full list) |

## Remote-access workflow

Common pattern when user is away:

1. Check if PC is alive → `uptime`
2. Unlock desktop → `loginctl unlock-session <ID>`; if LockedHint stays `yes` (GDM), use pynput keystroke method (section 5c)
3. Launch GUI app if needed (e.g. Chrome for a URL) → use `terminal(background=true)` with `DISPLAY=:0` — foreground `&` is not allowed
4. Screenshot → ffmpeg x11grab
5. Deliver to user → MEDIA tag in Telegram
6. User instructs next action (open app, run command, etc.)
