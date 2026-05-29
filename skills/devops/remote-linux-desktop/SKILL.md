---
name: remote-linux-desktop
description: 'Remote control of a Linux desktop via Hermes: webcam capture, screenshots, screen unlock, launch GUI apps from a remote Telegram/CLI session.'
tags: [remote, desktop, webcam, screenshot, screen-unlock, x11, linux, v4l2, ffmpeg]
category: devops
---

# Remote Linux Desktop Control

Control and monitor a Linux desktop PC remotely via Hermes agent — when you're away from home (office, commute, etc.) and need to check in.

**Use case:** User is at the office, Hermes runs on the home PC, user wants to see what's on screen, check the webcam, unlock the screen, or launch an application.

---

## Prerequisites

- `ffmpeg` installed (for camera + screenshot capture)
- X11 server running (any DM: GDM, SDDM, LightDM)
- `loginctl` (part of systemd — preinstalled on Ubuntu)
- GUI apps (`gnome-terminal`, etc.) available

---

## Camera / Webcam

### Check camera availability

```bash
ls -la /dev/video*
cat /sys/class/video4linux/video0/name   # shows human-readable name (e.g. "C270 HD WEBCAM")
```

### Capture a single image

**Recommended — capture directly to Hermes media root:**

```bash
mkdir -p ~/.hermes/image_cache/
ffmpeg -f v4l2 -video_size 640x480 -i /dev/video0 -frames 1 -update 1 -y ~/.hermes/image_cache/webcam.jpg
```

**Or capture to /tmp first for testing, then copy:**

```bash
ffmpeg -f v4l2 -video_size 640x480 -i /dev/video0 -frames 1 -update 1 -y /tmp/webcam.jpg
ls -la /tmp/webcam.jpg                    # check file size to guess if it's black
cp /tmp/webcam.jpg ~/.hermes/image_cache/ # copy to allowed root for delivery
```

**Key flags for ffmpeg camera capture:**
- `-f v4l2` — Video4Linux2 input (webcam)
- `-video_size 640x480` — resolution (try 1280x720 or 1920x1080 if camera supports it)
- `-i /dev/video0` — camera device (check `/dev/video*` for alternatives)
- `-frames 1` — capture exactly one frame
- `-update 1` — REQUIRED for single-image output (without it ffmpeg expects a sequence pattern like `%03d`)
- `-y` — overwrite output without asking

### Brightness / contrast / gamma adjustment (dark rooms)

When the webcam image is too dark, use the `eq` filter with brightness, contrast, saturation, and gamma parameters:

```bash
# Moderate boost: good for dim rooms
ffmpeg -f v4l2 -video_size 640x480 -i /dev/video0 -frames 1 -update 1 -y \
  -vf "eq=brightness=0.3:contrast=1.2:saturation=1.2" \
  -q:v 5 ~/.hermes/image_cache/webcam_terang.jpg

# Aggressive boost: for very dark scenes (adds gamma to reveal hidden details)
ffmpeg -f v4l2 -video_size 640x480 -i /dev/video0 -frames 1 -update 1 -y \
  -vf "eq=brightness=0.5:contrast=2.0:gamma=1.5" \
  -q:v 3 ~/.hermes/image_cache/webcam_terang.jpg
```

**Parameter ranges for `eq` filter:**
| Param | Range | Default | When to use |
|-------|-------|---------|-------------|
| `brightness` | -1.0 to 1.0 | 0.0 | Lighten/darken the whole image |
| `contrast` | 0.0 to 3.0 | 1.0 | Increase for washy/dim images |
| `saturation` | 0.0 to 3.0 | 1.0 | Boost colors after brightening |
| `gamma` | 0.1 to 10.0 | 1.0 | Reveal detail in near-black shadows (use 1.2-2.0 for dark webcam feeds) |

**Quality flag `-q:v`:** lower = better quality (range 1-31, default ~6). Use `-q:v 3` when you want maximum detail, `-q:v 8-10` for smaller file sizes over slow connections.

### Checking if image is mostly black

If the JPEG file size is tiny (2-3 KB for 640×480), the image is almost entirely black/dark. Normal 640×480 JPEG: 50-200 KB. Compare sizes:

```bash
ls -la /tmp/webcam.jpg
```

**Distinguishing "dark scene" from "no light hitting the sensor":**

| Symptom | File size (640×480) | Brightness fix works? | Cause |
|---------|-------------------|----------------------|-------|
| Dim but visible | 50-150 KB | ✅ Yes, `eq=brightness` helps | Low light, sensor has some data |
| Near-black | 10-30 KB | ⚠️ Partially, reveals grey shapes | Very dark room |
| Uniform black | 2-3 KB | ❌ No, stays same size | Camera covered / pitch dark — sensor gets zero light |

**Quick diagnostic:** apply brightness adjustment and check if file size changes significantly:
```bash
# Before
ls -la ~/.hermes/image_cache/webcam.jpg
# After brightness boost
ffmpeg -f v4l2 -video_size 640x480 -i /dev/video0 -frames 1 -update 1 -y \
  -vf "eq=brightness=0.5:contrast=1.5" \
  ~/.hermes/image_cache/webcam_bright.jpg
ls -la ~/.hermes/image_cache/webcam_bright.jpg
```
- **Size grew (e.g. 2 KB → 80 KB):** room is dim but recoverable — brightness worked.
- **Size barely changed (e.g. 2 KB → 3 KB):** sensor has zero useful light — physical light needed (turn on a lamp, uncover lens). Digital brightness adjustment only converts pure black to grey, revealing no detail.

### Identify camera type

```bash
# USB vs built-in — check sysfs path
readlink -f /sys/class/video4linux/video0
# USB path: /devices/.../usb3/3-1/...
# Built-in: /devices/.../pci/.../...

# USB vendor info
lsusb | grep -i camera
```

---

## Screenshot

### Take screenshot (X11)

Hermes runs as a service/daemon — `$DISPLAY` is typically NOT set. Always set it explicitly:

```bash
export DISPLAY=:0
ffmpeg -f x11grab -video_size 1920x1080 -i :0 -frames 1 -update 1 -y ~/.hermes/image_cache/screenshot.jpg
```

### Verify X server is available

```bash
ls /tmp/.X11-unix/X0   # X0 = display :0 is running
export DISPLAY=:0 && xdpyinfo | head -5   # confirms X server responds
```

### Image size tells a story

- Small file (50-100 KB for 1920×1080) — mostly uniform content, possibly lock screen or desktop with minimal UI
- Large file (300-2000 KB) — rich desktop with windows, browser tabs, wallpapers

---

## Screen Unlock

### Check lock status

```bash
loginctl list-sessions                    # find session ID (e.g. "2")
loginctl show-session 2 -p LockedHint     # "yes" = locked, "no" = unlocked
```

### Unlock the screen — method 1 (loginctl)

```bash
loginctl unlock-session 2
sleep 2
loginctl show-session 2 -p LockedHint    # verify: should say "no"
```

**Note:** Works with most display managers (SDDM, LightDM). On some systems `LockedHint` may not exist — check `loginctl show-session 2` for all properties.

**Ubuntu 24.04 + GDM quirk:** `loginctl unlock-session` alone is **NOT sufficient** for GDM (GNOME Display Manager). GDM bypasses PAM, so the unlock signal is ignored. You MUST use method 2 (pynput keystroke simulation) instead.

### Unlock the screen — method 2 (pynput keystrokes, REQUIRED for GDM)

When `loginctl unlock-session` fails (LockedHint stays "yes"), GDM lock screen needs actual keystroke simulation. `xdotool` is often not installed and `sudo` may be unavailable — use Python instead.

**Step 1 — Install pynput** (pip may need bootstrapping first):

```bash
python3 -m ensurepip   # only if pip is missing
python3 -m pip install pynput
```

**Step 2 — Send password + Enter via pynput:**

```bash
DISPLAY=:0 python3 -c "
from pynput.keyboard import Key, Controller
import time
k = Controller()
for c in 'PASSWORD_HERE':   # ask user for password first
    k.press(c); time.sleep(0.05); k.release(c); time.sleep(0.05)
k.press(Key.enter); time.sleep(0.05); k.release(Key.enter)
print('Unlock attempt sent')
"
```

Always **ask the user for their password** (via `clarify` tool) — never guess or store it.

**Step 3 — Verify:**

```bash
loginctl show-session 2 -p LockedHint   # should return LockedHint=no
```

Then re-take the screenshot to confirm.

---

## Finding and Focusing Windows (without xdotool)

When `xdotool` is not installed and `sudo` is unavailable, use `xprop` + `xwininfo` (preinstalled) for window discovery and `pynput` for mouse interaction.

### List all visible windows

```bash
# Get window IDs
xprop -root _NET_CLIENT_LIST

# Get names for each window
for wid in $(xprop -root _NET_CLIENT_LIST | grep -o '0x[0-9a-f]*'); do
    name=$(xprop -id "$wid" _NET_WM_NAME 2>/dev/null | grep -o '".*"' | head -1)
    echo "$wid  $name"
done
```

### Find a specific window by name

```bash
# Search for Chrome/Instagram windows
for wid in $(xprop -root _NET_CLIENT_LIST | grep -o '0x[0-9a-f]*'); do
    name=$(xprop -id "$wid" _NET_WM_NAME 2>/dev/null)
    if echo "$name" | grep -qi "instagram\|chrome\|reel"; then
        echo "FOUND: $wid -- $name"
        # Check if hidden
        state=$(xprop -id "$wid" _NET_WM_STATE 2>/dev/null)
        if echo "$state" | grep -q "HIDDEN"; then
            echo "  State: HIDDEN"
        else
            echo "  State: VISIBLE"
        fi
    fi
done
```

### Get window geometry (position + size)

```bash
xwininfo -id 0x1a0011b -stats
# Shows: Absolute upper-left X, Y, Width, Height
# Use this to know where to click/focus
```

### Focus a window and click inside it (pynput)

```bash
# Install pynput first if needed
python3 -m ensurepip 2>/dev/null
python3 -m pip install pynput

# Focus + click at a coordinate (e.g., center of video player)
DISPLAY=:0 python3 -c "
from pynput.mouse import Button, Controller
import time
mouse = Controller()
mouse.position = (960, 500)   # center of 1920x1080 screen
mouse.click(Button.left, 1)
"
```

### Move mouse to wake screen

If the monitor went to sleep or the screensaver activated, moving the mouse wakes it.

**IMPORTANT:** `mouse.move()` by itself may NOT wake a deep-sleep monitor — use a click instead which sends an actual X11 input event:

```bash
python3 -m pip install pynput   # if not already installed
DISPLAY=:0 python3 -c "
from pynput.mouse import Button, Controller
import time
m = Controller()
m.position = (500, 400)          # move to center-ish area first
m.click(Button.left, 1)          # actual click wakes the screen reliably
time.sleep(0.5)
"
```

## Launch GUI Applications

Set `DISPLAY=:0` so the app opens on the user's screen. Use `terminal(background=true)` — foreground `nohup &` wrappers are not allowed:

```bash
# In Hermes:
terminal(command="export DISPLAY=:0 && google-chrome", background=true)
```

Common apps:

| App | Command |
|-----|---------|
| Terminal | `gnome-terminal` |
| File manager | `nautilus` |
| Browser (Chrome) | `google-chrome` |
| Text editor | `gedit` |
| VS Code | `code` |

---

## Interacting with Browser Media (Instagram Reels, YouTube, etc.)

When controlling a browser remotely (e.g., Instagram Reel in Chrome on Bos's desktop), use these keyboard shortcuts after focusing the video area:

### Common Browser Media Shortcuts

| Key | Effect | Platform |
|-----|--------|----------|
| `k` | Play / Pause | Instagram, YouTube, Twitter/X |
| `m` | Mute / Unmute | Instagram, YouTube |
| `Space` | Play / Pause | YouTube, most HTML5 video |
| `f` | Fullscreen | YouTube |
| `j` / `l` | Rewind / Fast-forward (10s) | YouTube |
| `ArrowLeft` / `ArrowRight` | Seek backward/forward | YouTube, Instagram |

### Finding and Focusing the Video Player (without xdotool)

When the browser window is already open but not focused, use this sequence:

```python
# 1. Find window by name via xprop
# 2. Get its geometry via xwininfo
# 3. Click inside it via pynput
```

See "Finding and Focusing Windows (without xdotool)" section above for the full window-discovery flow.

### Debugging: Log Mouse Position

When clicks don't land where expected, print the current mouse position before/after each action:

```python
from pynput.mouse import Controller
mouse = Controller()
print(f"Before: {mouse.position}")   # (x, y)
mouse.position = (960, 540)
mouse.click(Button.left, 1)
print(f"After: {mouse.position}")
```

### Pitfalls for Media Interaction

- **Play button may not respond on first click** — Instagram Reels sometimes need TWO clicks: first to focus the player, second to play. Or use keyboard shortcut `k` instead which is more reliable.
- **Focus matters** — if `k` produces no effect, the video player likely doesn't have keyboard focus. Click inside the video area first, then press `k`.
- **Video might appear black/blank** on screenshot if the GPU compositor doesn't render video frames into the X11 grab buffer. This is normal — ask the user what they see on their end.
- **Key repeat can cause issues** — always `time.sleep(0.05)` between press and release to avoid key-repeat firing extra events.

---

## Delivering Images to Telegram

MEDIA tags only work for files in Hermes-approved directories:

```yaml
Approved roots:
  - ~/.hermes/image_cache/
  - ~/.hermes/audio_cache/
  - ~/.hermes/video_cache/
  - ~/.hermes/document_cache/
  - ~/.hermes/browser_screenshots/
  - Any dir in $HERMES_MEDIA_ALLOW_DIRS
```

**Always save captured images to `~/.hermes/image_cache/`** before sending. First ensure the directory exists:

```bash
mkdir -p ~/.hermes/image_cache/
```

Then capture directly to it, or copy after capture:

```bash
# Capture directly to the right place (recommended):
ffmpeg ... -y ~/.hermes/image_cache/webcam.jpg

# Or copy after capture (when testing /tmp first):
cp /tmp/webcam.jpg ~/.hermes/image_cache/
```

Then deliver via `send_message` with a MEDIA tag or include `MEDIA:path` in your response:

```
MEDIA:/home/who/.hermes/image_cache/webcam.jpg
```

**Note:** MEDIA tags only work for image/audio/video file types. For generic files (.tar.gz, .zip, .pdf, etc.), use direct Telegram API curl instead — see 📄 [`references/telegram-file-delivery.md`](references/telegram-file-delivery.md).

---

## SSH Remote Access

To enable SSH access from a laptop to the home PC (so the user can run `hermes` CLI remotely), see:

📄 [`references/ssh-remote-access.md`](references/ssh-remote-access.md)

Covers: installing openssh-server, checking IP, firewall rules, Tailscale for WAN access, and verification steps.

## Terminal AI Agent Workflow

This skill supports the "terminal AI agent" pattern — giving AI direct terminal access to create files, write logic, debug, and run apps autonomously. See:

📄 [`references/terminal-ai-agent-workflow.md`](references/terminal-ai-agent-workflow.md)

Covers: trend context, how Bos's Hermes + OpenCode setup maps to the pattern, and content/inspiration angles.

---

## Closing GUI Applications and Tabs

After launching an app remotely, the user may ask to close it. Two approaches:

### Close a specific tab (browser)

```bash
# Method 1 — kill by URL match (simplest, works with single tab)
pkill -f "google-chrome.*mail.google"   # closes chrome tabs matching "mail.google"

# Method 2 — send Ctrl+W via xdotool (requires xdotool installed)
sudo apt install xdotool -y  # if not installed
export DISPLAY=:0 && xdotool search --name "Gmail" windowactivate --sync && \
  sleep 0.5 && xdotool key Ctrl+w
```

### Close a specific app window

```bash
# By window title
export DISPLAY=:0 && xdotool search --name "Terminal" windowactivate --sync && \
  sleep 0.5 && xdotool key Ctrl+Shift+w   # or Alt+F4 to close window

# By PID (if you know the process ID)
kill <PID>

# By name pattern (use carefully — may kill all matching processes)
pkill gnome-terminal   # closes ALL gnome-terminal windows
```

### Background process cleanup

If the app was launched via `terminal(background=true)`, track its session ID and kill it:
```bash
process(action='kill', session_id='proc_xxxx')
```

For browser tabs specifically, `pkill -f` with a distinctive URL fragment is the most reliable approach since browser windows don't expose tab PIDs.

## Auto-detect Screen Resolution

Instead of hardcoding `1920x1080`, detect the actual monitor resolution:

```bash
export DISPLAY=:0
RES=$(xdpyinfo | grep dimensions | awk '{print $2}')   # e.g. "1920x1080"
ffmpeg -f x11grab -video_size "$RES" -i :0 -frames 1 -update 1 -y \
  ~/.hermes/image_cache/screenshot.jpg
```

Useful when the remote PC has a non-standard resolution or multiple monitors.

## Pitfalls

- **`$DISPLAY` is empty** — Hermes runs as a background service, not in the user's X session. Always `export DISPLAY=:0` before any X11 command (x11grab, gnome-terminal, xdpyinfo).
- **`ffmpeg` with x11grab needs `-update 1`** — without it, single-image output to a plain filename fails with an image-sequence error.
- **Screenshot file too small** — if the desktop is locked or has minimal content, the JPEG will be highly compressible (50-100 KB for 1920×1080). Take a screenshot, unlock, screenshot again to compare.
- **`gnome-terminal` may not open** if it's already running in a different user session or if `DISPLAY` is wrong. Try `xterm` as fallback.
- **MEDIA tags ignored silently** — if the file path is not under an approved root, the MEDIA attachment is silently dropped and only the text is delivered. Always use `~/.hermes/image_cache/`.
- **Camera shows black frames** in low light — the Logitech C270 and similar USB webcams need ambient light. Digital brightness adjustment only turns black to grey, not revealing detail. Advise the user to turn on room lights or point the camera at a lit area.
- **Sudo required** for most system-level changes (install SSH, modify MariaDB root auth, etc.). The user may need to run commands manually from their local terminal, or set up passwordless sudo for specific commands.
- **`xdotool key Ctrl+w` may not work** if the window isn't focused first or `xdotool` is not installed (common, esp. when sudo is unavailable). Use pynput alternatives:
  - Keyboard: `python3 -m pip install pynput` then use `Controller.key` for key simulation
  - Mouse: `Controller.mouse` for click, position, move
  - See section "Finding and Focusing Windows (without xdotool)" above.
- **`mouse.move()` may not wake a sleeping monitor** — some displays only wake on actual clicks. Use `mouse.click()` instead of just `mouse.move()` when trying to wake a screen that's gone dark. The wake-screen section above uses the click pattern.
- **Key-repeat timing with pynput** — `press()` followed immediately by `release()` can trigger OS-level key repeat if the delay between them is too short. Always use at least `time.sleep(0.05)` between press and release for single keystrokes.
- **`sudo` unavailable** — user's PC may require manual password entry. Prepare commands and let the user run them manually. Use `python3 -m ensurepip` + `python3 -m pip install pynput` for userland keystroke/mouse simulation — no sudo needed.
