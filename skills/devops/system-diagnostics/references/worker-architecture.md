# Worker Architecture — Event-Driven vs Blocking

Reference for explaining how server workers work. Use when teaching "gimana cara kerja worker di server" or diagnosing worker-related bottlenecks.

## Core Concept

Worker = a process that does one unit of work. A server creates multiple workers to handle multiple tasks concurrently.

Two fundamental models:

### 1. Blocking Workers (PHP-FPM, Apache prefork, uWSGI)

Each worker handles **one request at a time**, from start to finish. While processing, the worker is "blocked" — can't do anything else.

```
Time ──────────────────────────────────────►
Worker 1: [──── request A ────]             (blocked the whole time)
Worker 2:                     [── request B ──]
Worker 3:                         [─ request C ─]
```

- **Parallelism**: limited by worker count. 5 workers = max 5 concurrent requests.
- **Memory**: each worker keeps its own memory space (~20-30MB for PHP-FPM).
- **Simple**: no async logic needed in application code.
- **Tuning**: `pm.max_children` in PHP-FPM pool config.

**Formula**: `max_connections = pm.max_children` (for a single pool)

**RAM calculation**: `pm.max_children × avg_process_size + overhead`
Example: 10 workers × 25MB = 250MB minimum for the pool.

### 2. Event-Driven Workers (Nginx, Node.js, Redis)

Each worker handles **many connections simultaneously** using an event loop. When one request waits (I/O), the worker picks up another.

```
Worker 1: [─A─][─B─][─C─][─A─][─D─][─B─][─C─]  (interleaved, never idle)
```

- **Parallelism**: limited by CPU cores, not worker count.
- **Memory**: efficient — shared state, single process.
- **Complex**: requires non-blocking I/O in application code.
- **Tuning**: `worker_connections` in nginx.conf.

**Formula**: `max_connections ≈ worker_processes × worker_connections`
Example: 12 workers × 1024 connections = 12,288 concurrent connections.

### Why Both Exist Together (Nginx + PHP-FPM)

Most PHP/Laravel stacks use **both** in a reverse-proxy setup:

```
         Event-Driven           Blocking
        ┌──────────┐         ┌──────────┐
Request ─►  Nginx   ───► PHP-FPM  ──► Response
        │ 12 workers│         │ 5 workers │
        │ 12K conn  │         │ 5 conn    │
        └──────────┘         └──────────┘
```

Nginx handles the flood of connections efficiently. PHP-FPM workers are a scarce resource — each one holds ~25MB RAM while processing.

## Understanding PHP-FPM Pool Modes

PHP-FPM offers three process management modes that control how workers are spawned:

| Mode | Behavior | Use Case |
|------|----------|----------|
| **dynamic** | Starts with `pm.start_servers`, scales up to `pm.max_children` under load, scales down to `pm.min_spare_servers` when idle | General web traffic with variable load |
| **ondemand** | Zero workers at rest. Spawns on request, kills after `pm.process_idle_timeout` seconds idle | Low-memory servers, occasional traffic |
| **static** | Always keeps exactly `pm.max_children` workers running | Consistent high traffic, predictable load |

**How to identify the mode without reading config files:**

```bash
# Run this command twice, 2-3 seconds apart
ps aux | grep 'php-fpm: pool' | grep -v grep | wc -l
```

- **Count stays the same** → static mode (or fully saturated dynamic)
- **Count changes between runs** → dynamic mode
- **Count starts at 0 when idle** → ondemand mode

## Detecting Worker Saturation

### PHP-FPM Pool Exhaustion

When all PHP-FPM workers are busy:

1. Nginx gets a response from PHP-FPM: no available worker
2. Nginx returns **502 Bad Gateway** or the request queues at the FPM socket level
3. Latency spikes before the 502 appears

**Saturation check:**

```bash
# Look for PHP-FPM processes using 100% CPU
ps aux | grep 'php-fpm: pool' | grep -v grep | awk '{print $3, $11, $NF}' | sort -rn | head -5

# Check nginx error log for upstream timeouts
tail -20 ~/.valet/Log/nginx-error.log 2>/dev/null | grep -i 'upstream\|timeout\|502'
```

### Nginx Worker Saturation

Rare on modern hardware — nginx can handle thousands of connections per worker. Signs:

- `ss -tan | grep ':80' | wc -l` exceeds `worker_processes × worker_connections`
- System CPU soft lockup / load average spikes without PHP-FPM activity

## Queue Workers (Laravel Horizon / artisan queue:work)

Queue workers are a separate concept — they run in CLI, not via web server:

```bash
php artisan queue:work redis --sleep=3 --tries=3
```

- Each process is one worker, processing one job at a time (blocking)
- Run multiple processes via Supervisor `numprocs` directive for parallelism
- They don't compete with web PHP-FPM workers — separate process, separate memory

## Practical Diagnostics Scenario

When a user says "server lambat", follow this flow:

```
1. Cek nginx worker alive?   → ps aux | grep 'nginx: worker'
2. Cek PHP-FPM alive?        → ps aux | grep 'php-fpm: pool'
3. Cek worker count           → bandingin dengan pm.max_children
4. Cek CPU usage per worker   → ps aux | grep php-fpm | sort by %CPU
5. Cek RAM per worker         → ps aux | grep php-fpm | sort by %MEM
6. Cek nginx error log        → tail ~/.valet/Log/nginx-error.log
```

## Key Takeaways for Teaching

| User asks | Answer |
|-----------|--------|
| "Kenapa cuma 5 request bisa diproses bareng?" | PHP-FPM blocking — 5 workers = 5 concurrent requests. Tambah `pm.max_children` kalo RAM cukup. |
| "Nginx 12 workers itu buat apa?" | Event-driven — 12 workers handle ribuan koneksi. Bukan 12 request, tapi 12 jalur pemrosesan event. |
| "Workernya kurang?" | Cek RAM dulu: `free -h`. Tiap worker PHP ~25MB. 5 worker = 125MB. 20 worker = 500MB. |
| "Kenapa 502 Bad Gateway?" | Kemungkinan semua PHP-FPM worker sibuk atau PHP-FPM mati. Cek `valet status` atau `ps aux \| grep php-fpm`. |
| "Apa bedanya Valet pool sama www pool?" | Valet pool = user `who`, dipake Laravel Valet. www pool = user `www-data`, untuk aplikasi yang jalan langsung di nginx tanpa Valet. |
