---
name: laravel-valet-ubuntu
description: 'Setup Laravel Valet with multi-version PHP and nvm-managed Node.js on Ubuntu.'
tags: [php, valet, laravel, ubuntu, nvm, node, dev-environment]
category: devops
---

# Laravel Valet on Ubuntu — Setup

Install and configure **Valet Linux** with multiple PHP versions (7.4, 8.x) and Node.js via nvm on Ubuntu.

## Prerequisites

- Ubuntu (20.04+) with sudo access
- Composer installed globally (`/usr/local/bin/composer` or similar)
- nginx (installed automatically by Valet or pre-existing)

## Installation Steps

### 1. Install PHP Multi-Version via ondrej/php PPA

```bash
# Add PPA and update
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update

# Install required PHP versions with common extensions
# Laravel typically needs: fpm, cli, mysql, xml, mbstring, curl, gd, sqlite3, zip, bcmath, readline, soap, intl, opcache
PHP_EXTENSIONS="fpm cli mysql xml mbstring curl gd sqlite3 zip bcmath readline soap intl opcache"

for ver in 7.4 8.0 8.1 8.2 8.4; do
    sudo apt-get install -y php$ver-{fpm,cli,mysql,xml,mbstring,curl,gd,sqlite3,zip,bcmath,readline,soap,intl,opcache}
done
```

> **PHP 7.4 note:** Available via ondrej/php on Ubuntu 24.04 Noble despite being EOL.

### 2. Install Valet Linux

```bash
composer global require cpriego/valet-linux
# Ensure ~/.config/composer/vendor/bin is in PATH
valet install
```

### 3. Verify Services

```bash
valet status
# Expected: Php*-fpm is running, Nginx is running, Dnsmasq is running
```
### 4. Park Projects Directory

```bash
# IMPORTANT: always use the path as argument — \`cd dir && valet park\` may silently
# register the parent directory instead of the intended subdirectory
valet park /path/to/your/projects

# Verify
valet paths
```

## PHP Version Management

### Default PHP Version

Valet uses the system's default `php` version. Check which is active:

```bash
ls -la ~/.valet/valet.sock
# valet.sock -> valet83.sock  (currently PHP 8.3)
```

### Switch Default PHP (Global)

```bash
# NOTE: 'valet use' runs sudo internally — may fail from non-interactive contexts
# Run in your own terminal:
sudo valet use php8.2
```

The `valet use` command:
1. Stops current php-fpm
2. Disables it
3. Enables new php-fpm version
4. Symlinks valet.sock to the new version's socket
5. Updates `~/.valet/use_php_version`

#### Known Bug: `valet use php@X.Y` Fails on Ubuntu

On Valet Linux, running `valet use php@7.4` may produce this error:

```
E: Unable to locate package phpphp@7.4-fpm
```

**Root cause**: Valet Linux has a parsing bug where it concatenates `php` + the version argument literally, producing `phpphp@7.4-fpm` instead of `php7.4-fpm`. The `@` syntax (used by `valet isolate`) is not supported by `valet use` on some Valet Linux builds.

**Workaround** — manual PHP-FPM switch:

```bash
# 1. Stop current PHP-FPM
sudo systemctl stop php8.4-fpm
sudo systemctl disable php8.4-fpm

# 2. Start target PHP-FPM
sudo systemctl start php7.4-fpm
sudo systemctl enable php7.4-fpm

# 3. Now use 'valet isolate' for per-project (not 'valet use')
cd /path/to/project
valet isolate php@7.4

# 4. Verify
php -v
sudo systemctl status php7.4-fpm | head -3
```

This avoids the `valet use` parsing bug entirely. Use `valet isolate` for per-project versioning instead of global `valet use`.

### Per-Project PHP Version (Isolate)

```bash
cd /path/to/project
valet isolate php8.1

# Unisolate when done
valet unisolate
```

### Create Valet Socks for All PHP Versions

If `valet isolate` fails due to missing socket symlinks:

```bash
sudo ln -sf /run/php/php7.4-fpm.sock ~/.valet/valet74.sock
sudo ln -sf /run/php/php8.0-fpm.sock ~/.valet/valet80.sock
sudo ln -sf /run/php/php8.1-fpm.sock ~/.valet/valet81.sock
sudo ln -sf /run/php/php8.2-fpm.sock ~/.valet/valet82.sock
sudo ln -sf /run/php/php8.4-fpm.sock ~/.valet/valet84.sock
```

## Node.js via nvm

```bash
# Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

# Load it
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Install specific versions
nvm install 16    # LTS Gallium
nvm install 24    # LTS Krypton (or latest)
nvm alias default 24
```

### Per-Version npm Helper

When you need to run `npm` commands with a specific Node version (e.g., old projects that need Node 16), create a wrapper script in `~/.local/bin/`:

```bash
cat > ~/.local/bin/npm16 << 'SCRIPT'
#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 16 >/dev/null 2>&1
exec npm "$@"
SCRIPT
chmod +x ~/.local/bin/npm16

# Usage
npm16 install
npm16 run dev
```

Create similar wrappers (`npm24`, `npm20`, etc.) for any version you need. Name them `node16`, `node24` if you need the Node binary directly rather than npm.

## Database Setup

### Install MariaDB

MariaDB is usually installed alongside Valet or available via apt:

```bash
sudo apt-get install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
```

### GUI Database Tools

Recommended free GUI clients for managing MariaDB/MySQL:

| Tool | Install | Notes |
|------|---------|-------|
| **Beekeeper Studio** | `sudo snap install beekeeper-studio` | Open source, modern UI, multi-platform |
| **DBeaver** | `sudo snap install dbeaver-ce` | Most feature-rich (ER diagrams, export), Java-based |
| **phpMyAdmin** | Extract to a Valet-parked dir | Web-based, convenient |

### Set Root Password

Ubuntu's MariaDB often uses `unix_socket` auth by default. To set a password-based root login:

```bash
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('root'); FLUSH PRIVILEGES;"
```

For detailed MariaDB auth troubleshooting, see `references/mariadb-auth.md`.

### Import Large SQL Dumps

For files 500MB+, use `pv` (pipe viewer) to track progress:

```bash
sudo apt-get install -y pv

# Create database
mysql -u root -proot -e "CREATE DATABASE IF NOT EXISTS dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# Import with progress bar
pv /path/to/dump.sql | mysql -u root -proot dbname
```

`pv` shows transfer speed, elapsed time, and estimated completion time. For files over 1GB, expect several minutes — check progress periodically with:

```bash
# Check how many tables are created so far
mysql -u root -proot -e "SELECT COUNT(*) AS tables FROM information_schema.tables WHERE table_schema='dbname';"

# Check imported size
mysql -u root -proot -e "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema='dbname';"
```

**Precise file-read progress** (bypasses MySQL buffering): when `pv` is running in background, query its file descriptor position directly via `/proc`:

```bash
# Find pv PID
ps aux | grep 'pv.*\.sql' | grep -v grep

# Read position (bytes read so far) vs total file size
pos=$(cat /proc/<PID>/fdinfo/3 2>/dev/null | grep '^pos:' | awk '{print $2}')
total=$(stat -c%s /path/to/dump.sql)
echo "Progress: $(( pos * 100 / total ))% ($(( pos / 1024 / 1024 ))MB / $(( total / 1024 / 1024 ))MB)"
```

This shows raw bytes consumed from the file, independent of how much MySQL has processed. Import progress (bytes read) often runs ahead of MySQL processing (tables created) — compare both to decide if the import is genuinely stuck or just catching up.

For detailed MariaDB import patterns, see `references/large-import.md`.

## Accessing Sites

With Valet installed and a directory parked, sites are automatically served at:

```
http://<directory-name>.test
```

Example: for `/home/who/herd/my-laravel-app`, visit `http://my-laravel-app.test`

## Pitfalls

- **`valet park` without path argument**: Running `cd /path && valet park` may silently register the parent directory instead of the intended subdirectory (observed when `/home/who/herd` registered `/home/who` instead). Always use `valet park /absolute/path`.
- **`valet use` vs `valet isolate` confusion**: `valet use php@X.Y` changes PHP **globally** for ALL sites. `valet isolate php@X.Y` changes PHP for only the CURRENT project (creates a project-specific `.valet-phprc` or nginx config). If you accidentally run `valet use` when you meant `valet isolate`, you'll break other sites that depend on a different PHP version. Always use `isolate` for per-project needs; use `use` only when you deliberately want to change the system-wide default. Undo a mistaken `valet use` by re-running it with the original version.
- **PHP extensions**: Not all PECL extensions are available via apt for older PHP versions (e.g., 7.4). Use `pecl install` as fallback.
- **Valet config path**: Config lives at `~/.valet/config.json`. The `VALET_HOME_PATH` env var can override.
- **Nginx already running**: Valet reconfigures existing nginx — it won't conflict. Verify nginx is running after install: `systemctl status nginx`.
- **`valet parked` not available**: In Valet Linux, `valet parked` does not exist. To list parked sites, read `~/.valet/config.json` for the `paths` array, then list directories under each path — all folders there are served as `foldername.test`. Use `valet links` for symlinked sites only.
- **MariaDB/MySQL root auth**: Ubuntu's MariaDB often uses `unix_socket` auth for root, meaning only the system `root` user can connect. PHP apps connecting as `root@localhost` will get 'Access denied'. Either create a dedicated DB user for the app or switch root to `mysql_native_password`. See `references/mariadb-auth.md` for concrete fix commands.
- **Large SQL imports**: Background import processes may not show `pv` progress if the pipe buffers — pv writes progress to stderr which gets captured but may appear empty on poll. Use a short `sleep` + query against `information_schema` to check real progress during a running import. For precise file-read position, use `/proc/<pv-PID>/fdinfo/3` (see Import Large SQL Dumps section). See `references/large-import.md` for patterns.
- **Dual-parked identical paths**: If two paths in `valet paths` contain the same directory tree (e.g., `/home/who/herd` and `/media/who/Dota\ 2/Herd` are symlinked or mirrored), Valet serves the same site under both names but may use different config files. Debug errors on a site by checking which parked path's index.php is executing — PHP error stack traces show the actual path. Check the real symlink chain with `readlink -f /path/to/project`.

## Troubleshooting Valet Sites

When a Valet-served site returns an error (HTTP 500, blank page, etc.), follow this workflow:

### 1. Quick Health Check

```bash
# Are Valet services alive?
valet status

# Is the site responding?
curl -sI http://site-name.test
# Look at HTTP status code
```

### 2. Identify the Project Type

```bash
# Laravel?
ls artisan 2>/dev/null && echo "Laravel"

# CodeIgniter 3?
ls application/ 2>/dev/null && echo "CodeIgniter 3"

# Generic PHP?
ls index.php 2>/dev/null && echo "Generic PHP"
```

Different frameworks store logs and config differently — this determines where to look next.

### 3. Check Environment Config

```bash
# Laravel
cat .env 2>/dev/null

# CodeIgniter 3 (via .env or application/config/database.php)
cat .env 2>/dev/null
cat application/config/database.php 2>/dev/null
```

Check DB credentials are correct and the DB server is reachable.

### 4. Check Application Logs

```bash
# Laravel
tail -50 storage/logs/laravel.log

# CodeIgniter 3
tail -30 application/logs/log-*.php

# Generic / unknown
tail -50 logs/*.log 2>/dev/null
```

### 5. Check Nginx Error Log

**Valet's nginx error log is at `~/.valet/Log/nginx-error.log`** — NOT `/var/log/nginx/error.log`.

```bash
tail -30 ~/.valet/Log/nginx-error.log
```

This often reveals the exact PHP fatal error, including the stack trace.

### 6. Check PHP-FPM Version

Valet runs PHP-FPM via a unix socket at `~/.valet/valet.sock`. To see which PHP version is active:

```bash
# See which PHP-FPM master is running
ps aux | grep php-fpm | grep master

# Find the PHP version in use
ls -la ~/.valet/valet.sock
# If symlinked, e.g. valet.sock -> valet83.sock (PHP 8.3)

# Cross-check: `valet status` may claim a different PHP version than reality
# due to stale socket symlinks — always verify with `ps aux` above
```

### 7. Check Database Service

```bash
# MariaDB
systemctl status mariadb 2>/dev/null || service mariadb status

# MySQL
systemctl status mysql 2>/dev/null || service mysql status

# `service <name> status` works without sudo (falls back to init.d) —
# useful when sudo is unavailable in non-interactive contexts
```

If the site uses `root@localhost` as DB user and gets "Access denied", the issue is likely MariaDB's default `unix_socket` auth plugin (see pitfalls above).

## PHP Version Compatibility

If the project is older (CodeIgniter 3, Symfony 3/4, Laravel 5/6) and Valet runs PHP 8.3+:

- Check `composer.json` for `php` version constraint
- Run `composer check-platform-reqs 2>/dev/null`
- Old vendor packages (e.g., GuzzleHttp <7) may emit deprecation warnings on PHP 8.3/8.4 — these are usually non-fatal but check logs
- Try isolating the site to an older PHP version: `valet isolate php7.4` or `valet isolate php8.1`

## Quick PHP CLI Test (Bypass nginx/FPM)

When a Valet-served app returns HTTP 500 but you can't see the full error in nginx logs, test it directly via PHP CLI by simulating a web request's `$_SERVER` variables. This technique works for any PHP app (Laravel, CodeIgniter 3, Symfony, WordPress) and reveals PHP warnings, deprecation notices, and the *first* fatal error without going through nginx/PHP-FPM.

### Generic (works for any framework)

```bash
cd /path/to/project
php -d error_reporting=E_ALL -d display_errors=1 -r '
$_SERVER["REQUEST_METHOD"] = "GET";
$_SERVER["SERVER_PROTOCOL"] = "HTTP/1.1";
$_SERVER["HTTP_HOST"] = "site.test";
$_SERVER["SCRIPT_FILENAME"] = "index.php";
$_SERVER["SERVER_NAME"] = "site.test";
$_SERVER["DOCUMENT_ROOT"] = getcwd();
$_GET = ["route" => "/"];  # adjust per framework
try {
    ob_start();
    require "index.php";
    $output = ob_get_clean();
    echo "SUCCESS (len=" . strlen($output) . ")";
} catch (Throwable $e) {
    echo get_class($e) . ": " . $e->getMessage() . " in " . $e->getFile() . ":" . $e->getLine();
    echo PHP_EOL . $e->getTraceAsString();
}
' 2>&1 | tail -30
```

**What to look for in the output:**
- **PHP Deprecated / Warning** lines — non-fatal but indicate version mismatches
- **Fatal error** with stack trace — the root cause (e.g., DB auth failure, missing class)
- **`SUCCESS (len=N)`** — app loaded without errors

### CodeIgniter 3

CI3's `index.php` requires `$_SERVER['REQUEST_METHOD']` at the top — without it you get `Warning: Undefined array key "REQUEST_METHOD"` but the app may still continue. If you see this, the error is likely downstream.

For CI3, also set `$_GET['ci']` to trigger a specific controller:
```bash
$_GET = ["ci" => "welcome"];
```

### When PHP CLI passes but Valet still returns 500

If the CLI test succeeds but the Valet-served site still returns HTTP 500:
1. Check `~/.valet/Log/nginx-error.log` for PHP-FPM errors
2. Verify the PHP-FPM user (`www-data` vs your user) has file permissions
3. Check if `valet isolate` changed the PHP version away from what the app expects
4. Compare `php -v` (CLI version) vs the PHP-FPM version via `ps aux | grep php-fpm | grep master`

### Quick Reference

| Symptom | Likely Cause | Where to Look |
|---------|-------------|---------------|
| HTTP 500 on all pages | PHP fatal error | `~/.valet/Log/nginx-error.log` |
| Blank white page | PHP error / memory | Same + app logs |
| Database error (Access denied) | Bad DB creds or auth plugin | `.env`, `application/config/database.php` |
| 502 Bad Gateway | PHP-FPM down | `valet status`, `sudo systemctl restart php*-fpm` |
| 404 on routes | Framework routing | Check if project type matches expectations |
| Old project broken | PHP version mismatch | `valet isolate php7.4` or `php8.1` |

## Verification Checklist

```bash
# PHP
php7.4 -v && php8.0 -v && php8.1 -v && php8.2 -v && php8.3 -v && php8.4 -v

# Node
node -v  # should be default (24)
nvm ls

# Valet
valet --version
valet status
valet paths
```
