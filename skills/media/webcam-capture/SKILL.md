---
name: webcam-capture
description: Capture images or video from a USB/built-in webcam on Linux using ffmpeg or fswebcam. Deliver captures to the user via messaging platforms.
trigger: User asks to take a photo/selfie from the PC camera, check webcam, or capture a room view. Also relevant for remote-access scenarios where the user is away from the PC.
---

# Webcam Capture

Capture images from a connected webcam on Linux and deliver them to the user.

## Prerequisites

- **ffmpeg** (usually pre-installed; `apt install ffmpeg` if missing)
- Camera device at `/dev/video0` (or `/dev/video1` for secondary)

## Steps

### 1. Check available camera devices

```bash
ls -la /dev/video*
v4l2-ctl --list-devices   # if v4l-utils is installed
```

If no `/dev/video*` appears, the camera isn't detected (check USB connection, drivers).

### 2. Identify camera hardware

```bash
cat /sys/class/video4linux/video*/name
```

Shows the actual device name (e.g. "C270 HD WEBCAM", "Integrated Camera") without needing `v4l2-ctl`.

### 3. Capture a single image with ffmpeg

**⚠️ Critical: use `-update 1`** — without it, ffmpeg expects a sequence pattern like `%03d` and fails with "filename does not contain an image sequence pattern".

```bash
ffmpeg -f v4l2 -video_size 640x480 -i /dev/video0 -frames 1 -update 1 -y /tmp/webcam.jpg
```

Options explained:
- `-f v4l2` — Video4Linux2 input format
- `-video_size 640x480` — resolution (adjust as needed: 1280x720, 1920x1080)
- `-i /dev/video0` — camera device
- `-frames 1` — capture exactly one frame
- `-update 1` — overwrite the output file for single-image mode (REQUIRED)
- `-y` — overwrite output file without asking

### 4. Fix dark/grainy image

If the captured image is too dark, add a brightness/contrast filter via `-vf`:

```bash
ffmpeg -f v4l2 -video_size 640x480 -i /dev/video0 -frames 1 -update 1 -y \
  -vf "eq=brightness=0.3:contrast=1.2:saturation=1.2" /tmp/webcam_terang.jpg
```

Parameter ranges:
- `brightness` — default 0.0, range -1.0 to 1.0 (start with 0.3, increase if still dark)
- `contrast` — default 1.0, range 0.0 to 2.0 (1.0–1.5 usually enough)
- `saturation` — default 1.0, range 0.0 to 3.0

A JPEG under ~10KB for 640×480 after adjustment still means the frame is essentially black — digital brightness boost can't recover detail from pure black. Try adding light or removing the camera cover.

### 5. Alternative: capture with fswebcam

```bash
sudo apt install fswebcam -y   # if not installed
fswebcam -r 640x480 --jpeg 85 -D 1 /tmp/webcam.jpg
```

### 4. Copy to Hermes-allowed media directory

⚠️ **CRITICAL**: The file **must** be under an allowed Hermes media delivery root. `/tmp/` is **NOT** allowed and will silently fail to deliver.

Copy to one of these directories first:

```bash
cp /tmp/webcam.jpg ~/.hermes/image_cache/webcam.jpg
```

Allowed Hermes media roots (from `gateway/platforms/base.py`):
| Directory | Purpose |
|-----------|---------|
| `~/.hermes/image_cache/` | Images (photos, screenshots) |
| `~/.hermes/audio_cache/` | Audio files |
| `~/.hermes/video_cache/` | Video files |
| `~/.hermes/document_cache/` | Documents |
| `~/.hermes/browser_screenshots/` | Browser screenshots |

All five auto-create if they don't exist. The config env var `HERMES_MEDIA_ALLOW_DIRS` can add custom directories (colon- or comma-separated).

### 5. Deliver to user

Use `send_message` with the `MEDIA:` prefix pointing to the file under the allowed directory:

```
send_message(target="telegram", message="MEDIA:/home/who/.hermes/image_cache/webcam.jpg")
```

You can also inline MEDIA in a response text:
```
📸 Foto kamera!

MEDIA:/home/who/.hermes/image_cache/webcam.jpg
```

### 6. Cleanup (optional)

```bash
rm ~/.hermes/image_cache/webcam.jpg
```

## Pitfalls

| Pitfall | Solution |
|---------|----------|
| **ffmpeg: "does not contain an image sequence pattern"** | Add `-update 1` flag |
| **ffmpeg: "Permission denied" for /dev/video*** | User needs to be in the `video` group: `sudo usermod -aG video $USER` then re-login |
| **Image is completely black/dark** | Webcam may be covered or room is too dark; try with lighting or check if camera has a privacy shutter. A JPEG file under ~10KB for 640×480 likely means a near-black image. |
| **Camera not found (/dev/video* empty)** | Check USB connection, try `lsusb` to see if camera is detected at hardware level |
| **grainy/low quality** | Increase resolution: `-video_size 1280x720` or `1920x1080` |
| **MEDIA tag sent but image doesn't appear in chat** | File path not in an allowed media root. Run `cp` to `~/.hermes/image_cache/` and use that path in MEDIA. |

## Remote-access scenario

When the user is away from the PC and I'm running on their home machine, webcam capture serves as a quick "room check" — verifying the PC is at the expected location, or just sending a fun snapshot.
