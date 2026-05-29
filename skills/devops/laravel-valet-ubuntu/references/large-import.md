# Large SQL Import Patterns

Importing SQL dumps over 500MB requires special handling to avoid timeouts,
silent failures, and impatience.

## Quickest: pv + pipe

```bash
sudo apt-get install -y pv
pv /path/to/dump.sql | mysql -u root -proot dbname
```

## Progress Monitoring During Import

`pv` writes its progress bar to stderr. When run in a background Hermes
process (`terminal(background=true)`), the output may appear empty on
`process(action='poll')` because stderr gets buffered.

**Do not assume the import is stuck.** Check real progress against the DB:

```bash
# Tables created so far
mysql -u root -proot -e \
  "SELECT COUNT(*) AS tables FROM information_schema.tables WHERE table_schema='dbname';"

# Data imported so far (MB)
mysql -u root -proot -e \
  "SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 1) AS 'Size (MB)' FROM information_schema.tables WHERE table_schema='dbname';"
```

A healthy 1.3GB import creates ~178 tables within the first 90 seconds and
finishes in ~3 minutes on a modern SSD.

## Alternative: mysql-source (more stable for very large files)

```bash
mysql -u root -proot
> CREATE DATABASE IF NOT EXISTS dbname;
> USE dbname;
> source /path/to/dump.sql;
```

## What to Check After Import

- **Row counts** on a few known tables to sanity-check
- **Indexes**: `SHOW INDEX FROM important_table;`
- **Foreign keys**: `SELECT TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE REFERENCED_TABLE_SCHEMA = 'dbname';`
- **Storage engine**: `SELECT TABLE_NAME, ENGINE FROM information_schema.TABLES WHERE TABLE_SCHEMA='dbname' AND ENGINE IS NOT NULL;`
- **Character set**: `SHOW CREATE TABLE important_table;`

## Pitfalls

- **Pipe buffering**: `pv` progress may not show until the pipe completes
  when stderr is captured by a non-TTY process. Use the `information_schema`
  queries above as a reliable alternative.
- **Wait timeout**: `process(action='wait')` in Hermes is clamped to 60s.
  For multi-minute imports, use `notify_on_complete=true` on the background
  terminal and poll periodically via `information_schema`.
- **Duplicate key errors**: The import fails partially if the dump contains
  rows that violate unique constraints. Check `mysql` exit code (0 = success).
- **max_allowed_packet**: Large rows (BLOB, TEXT, MEDIUMTEXT) may be silently
  truncated. Check `SHOW VARIABLES LIKE 'max_allowed_packet';` — raise to
  `256M` or `512M` in `/etc/mysql/mariadb.conf.d/50-server.cnf` if needed.
