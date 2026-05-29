# MariaDB / MySQL Root Auth Issues on Ubuntu

Ubuntu's MariaDB (and MySQL) often configure the `root` user with `unix_socket`
authentication by default. This means only the system `root` user can log in
via the Unix socket — password-based login for `root@localhost` is denied.

PHP apps running under the `www-data` or `who` user that try to connect as
`root@localhost` will get:

```
mysqli_sql_exception: Access denied for user 'root'@'localhost'
```

## Fix Options

### Option A: Create a dedicated database user (recommended)

```bash
# Connect as system root (requires sudo)
sudo mysql -e "CREATE USER IF NOT EXISTS 'homestead'@'localhost' IDENTIFIED BY 'secret';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'homestead'@'localhost' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"
```

Then update your app's `.env`:
```
DB_USERNAME=homestead
DB_PASSWORD=secret
```

### Option B: Switch root to mysql_native_password

```bash
sudo mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('your_password');"
sudo mysql -e "FLUSH PRIVILEGES;"
```

### Option C: Create a user that matches your system username

If your app's `.env` uses `DB_USERNAME=who` (your login user):

```bash
sudo mysql -e "CREATE USER IF NOT EXISTS 'who'@'localhost' IDENTIFIED BY 'secret';"
sudo mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'who'@'localhost' WITH GRANT OPTION;"
sudo mysql -e "FLUSH PRIVILEGES;"
```

## Diagnosing

### Check current auth method

```bash
sudo mysql -e "SELECT user, host, plugin FROM mysql.user WHERE user='root';"
```

Expected output for unix_socket:
```
+------+-----------+-------------+
| user | host      | plugin      |
+------+-----------+-------------+
| root | localhost | unix_socket |
+------+-----------+-------------+
```

### Check if MariaDB is running (without sudo)

```bash
service mariadb status
# or
ps aux | grep mariadb | grep -v grep
```
