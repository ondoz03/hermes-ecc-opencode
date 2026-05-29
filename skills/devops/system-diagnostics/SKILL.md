---
name: system-diagnostics
description: 'Run comprehensive system health checks: CPU, RAM, GPU, disk, network, running applications, and temperature on Linux.'
tags: [system, diagnostics, health-check, monitoring, linux, hardware, nvidia, gpu]
category: devops
---

# System Diagnostics — PC Health Check

Run a comprehensive health check on a Linux PC covering hardware, resource usage, running applications, and network.

Use when the user asks:
- "Check status PC saya"
- "Cek RAM / CPU / VGA"
- "Aplikasi apa aja yang kebuka?"
- "How is my PC doing?"
- "Kesehatannya gimana?"
- Any request about system performance, running processes, or hardware diagnostics

## All-in-One Health Check

Run once for a complete snapshot:

```bash
echo "=== UPTIME ===" && uptime && echo "" && \
echo "=== CPU ===" && lscpu | grep -E "Model name|^CPU\(s\)|Thread|Core|Socket" && echo "" && \
echo "=== RAM ===" && free -h && echo "" && \
echo "=== DISK ===" && df -h / && echo "" && \
echo "=== LOAD ===" && cat /proc/loadavg && echo "" && \
echo "=== TOP PROSES BY CPU ===" && ps aux --sort=-%cpu | head -6 && echo "" && \
echo "=== TOP PROSES BY MEM ===" && ps aux --sort=-%mem | head -6 && echo "" && \
echo "=== SUHU ===" && sensors 2>/dev/null | head -10 || echo "sensors not available" && echo "" && \
echo "=== KONEKSI ===" && ip -br addr 2>/dev/null | grep -v lo
```

## Individual Checks

### RAM

```bash
free -h
# Shows: total, used, free, shared, buff/cache, available
# 'available' is the real number to watch — it's what apps can actually use
cat /proc/meminfo | head -10   # more detailed breakdown
```

### CPU

```bash
lscpu | grep -E "Model name|^CPU\(s\)|Thread|Core|Socket"
uptime          # load average (1min, 5min, 15min) — below #cores = healthy
cat /proc/loadavg
```

### GPU / VGA

**NVIDIA:**
```bash
nvidia-smi
# Shows: GPU name, driver version, CUDA version, temp, power, VRAM usage, processes
lspci | grep -iE "vga|3d|display"          # hardware model
lspci -k | grep -A3 -iE "vga|3d"           # kernel driver in use
lsmod | grep nvidia                          # loaded kernel modules
```

**AMD / Intel:**
```bash
glxinfo -B 2>/dev/null | head -20
lspci | grep -iE "vga|3d|display"
```

### Disk

```bash
df -h              # all mounts
df -h /            # system partition only
df -h /path        # specific mount point
```

### Running Applications (GUI)

Use `ps aux` with a grep of known GUI process names:

```bash
ps aux | grep -iE "chrome|firefox|nautilus|thunar|code|sublime|gedit|postman|slack|discord|telegram|vlc|libreoffice|eog|evince|gimp|steam" | grep -v grep
```

Key indicators:
- **Chrome/Chromium**: Many renderer processes is normal for multiple tabs
- **Steam/steamwebhelper**: Multiple processes for the Steam client
- **File managers** (nautilus/thunar): Usually one process per window
- **Document viewers** (evince/eog): One per open document

### Worker & Process Architecture

Inspect and explain how server worker processes work — nginx, PHP-FPM, queue workers, etc. Useful when the user asks about server internals, performance bottlenecks, or "gimana cara kerja worker di server".

#### Nginx Workers

```bash
# Master + all worker processes
ps aux | grep 'nginx:' | grep -v grep

# Worker count vs CPU cores
echo -n "nginx workers: "; ps aux | grep 'nginx: worker' | grep -v grep | wc -l
echo -n "CPU threads:   "; nproc
```

Nginx uses **event-driven / non-blocking** I/O — each worker can handle thousands of concurrent connections simultaneously. Worker count = `worker_processes` in nginx.conf (often `auto` = CPU core count).

#### PHP-FPM Workers

```bash
# All PHP-FPM master and worker processes
ps aux | grep 'php-fpm:' | grep -v grep

# Per-pool breakdown
echo "=== PHP-FPM Pool Summary ===" && \
ps aux | grep 'php-fpm: pool' | grep -v grep | awk '{print $NF}' | sort | uniq -c | sort -rn

# Which PHP-FPM version is active for Valet
ls -la ~/.valet/valet.sock 2>/dev/null
```

PHP-FPM uses **blocking** workers — each worker handles exactly one request at a time. If all workers are busy, new requests queue.

#### Quick Architecture Summary

```bash
echo "=== Worker Architecture ===" && \
echo "" && \
echo "--- Nginx Workers ---" && \
ps aux | grep 'nginx: worker' | grep -v grep | awk '{print "  PID "$2" — user "$1}' && \
echo "" && \
echo "--- PHP-FPM Pools ---" && \
ps aux | grep 'php-fpm: pool' | grep -v grep | awk '{count[$NF]++} END {for (pool in count) print "  "pool": "count[pool]" workers"}' && \
echo "" && \
echo "--- PHP Versions Active ---" && \
ps aux | grep 'php-fpm: master' | grep -v grep | sed 's/.*\///' | sed 's/\/php-fpm.conf//' | awk '{print "  "$0}' | sort
```

#### Visualizing the Request Flow

When explaining to the user, draw the flow:

```
Client → Nginx (1 of N workers accepts, non-blocking)
           → PHP-FPM (1 of M pool workers picks it up, blocking)
             → Execute PHP/Laravel → DB/Redis/API
           ← PHP-FPM returns response
         ← Nginx sends back to client
```

Key insight: **Nginx's workers can handle thousands of connections** because they're event-driven. **PHP-FPM workers can only handle as many requests as there are workers** because each blocks until PHP finishes executing.

#### Quick Diagnostic: Are workers saturated?

```bash
# Active connections to nginx
echo -n "Active nginx connections: "
ss -tan | grep ':80\|:443' | grep ESTAB | wc -l

# PHP-FPM process count change over time (run twice, 2s apart)
echo "PHP-FPM workers now: $(ps aux | grep 'php-fpm: pool' | grep -v grep | wc -l)"
sleep 2
echo "PHP-FPM workers 2s later: $(ps aux | grep 'php-fpm: pool' | grep -v grep | wc -l)"
```

If worker count fluctuates, the pool is in **dynamic** mode (spawns on demand). If it's steady, it's **static** or all workers are saturated.

#### Pitfalls

- **`worker_processes auto`** = number of CPU cores, not threads — on Ryzen 5500U (6 cores, 12 threads), `auto` may give 6 or 12 depending on OS/nginx build. Use `nproc` to cross-check.
- **PHP-FPM pool config** may be unreadable without sudo — the pool paths are under `/etc/php/*/fpm/pool.d/`. Use `ps aux` to observe behavior instead.
- **Valet vs default `www` pool**: Valet runs its own pool (user `who`), separate from the system `www` pool (user `www-data`). Don't confuse them.
- **`service <name> status`** works without sudo — useful when sudo isn't available. Falls back to init.d if systemd isn't the init.

For deeper explanation of worker architecture types (event-driven vs blocking), see `references/worker-architecture.md`.

### Network

```bash
ip -br addr | grep -v lo    # active interfaces with IPs
ip link                     # link status (UP/DOWN)
```

### Temperature

```bash
sensors                       # all sensors (if installed)
# Typical healthy temps:
#   CPU idle: 35-55°C
#   GPU idle: 35-60°C
#   Under load: 70-85°C (safe up to ~95°C for most CPUs)
```

### Uptime

```bash
uptime
# Format: "19:16:44 up 9:38, 1 user, load average: 0.37, 0.54, 0.50"
# 9:38 = hours:minutes since boot
# load average: 1min, 5min, 15min averages
```

## Health Score Card

Present results as a table with color-coded status:

| Component | 🟢 Healthy | 🟠 Warning | 🔴 Critical |
|-----------|-----------|-----------|------------|
| **CPU** | Load < cores, temp < 70°C | Load ~= cores, temp 70-85°C | Load > cores×2, temp > 85°C |
| **RAM** | Available > 25% total | Available 10-25% | Available < 10% |
| **GPU** | Temp < 70°C, VRAM < 80% | Temp 70-85°C, VRAM 80-95% | Temp > 85°C, VRAM > 95% |
| **Disk (system)** | Used < 75% | Used 75-90% | Used > 90% |
| **Disk (data)** | Used < 80% | Used 80-95% | Used > 95% |

## Pitfalls

- **`sensors` not installed**: `sudo apt-get install lm-sensors` on Debian/Ubuntu. Without it, temperature check fails silently.
- **`nvidia-smi` not available**: Either no NVIDIA GPU, or the proprietary driver isn't installed. Check with `lspci | grep -i nvidia` first.
- **No desktop environment**: On headless servers, `ps aux | grep chrome/nautilus/etc` will return nothing — that's expected.
- **`free -h` shows low "free" but high "available"**: Linux uses free RAM for disk caching. "Available" is what matters — it shows memory reclaimable for applications.
- **Load average > #cores**: Not necessarily bad short-term. Sustained high load over 5-15min indicates a bottleneck.
- **GPU process listing**: `nvidia-smi` shows "G" (Graphics) and "C" (Compute) processes. Most apps use "G". Hermes/delegate_task may show "C" briefly during compute workloads.
- **`service` vs `systemctl`**: `service <name> status` works without sudo on systems without systemd or when sudo is unavailable — useful in non-interactive agent contexts.
