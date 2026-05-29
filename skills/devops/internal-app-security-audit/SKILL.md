---
name: internal-app-security-audit
description: Systematic security audit for internal/company web applications (Laravel, PHP, CodeIgniter, etc.) — unauthorized and authorized testing. Covers PHP EOL detection, .env exposure, security headers, SQLi on login, path enumeration, source code analysis, framework fingerprinting, rate limiting, and IT-team reporting format. Use when asked to audit a company's internal web app, when given admin/login access to an internal app, or when assessing risk for a PHP/Laravel/CodeIgniter application.
---

# Internal Web App Security Audit

Systematic approach for auditing internal/company web applications. Different from bug bounty — audience is IT team, goal is risk assessment, standards are internal policy not CVSS.

## Phase 1: Pre-Auth (Unauthorized)

Run these tests WITHOUT any login credentials first.

### 1.1 Technology Fingerprint
```bash
# Security headers
curl -sI https://target.com | grep -iE "strict-transport-security|content-security-policy|x-frame-options|x-content-type-options|referrer-policy|x-xss-protection"

# Server info
curl -sI https://target.com | grep -iE "server|x-powered-by|set-cookie"

# PHP version check
curl -s https://target.com/phpinfo.php | grep "PHP Version" && echo "PHPINFO EXPOSED!"
```

### 1.2 PHP-Specific Checks
| Path | Signal | Risk |
|------|--------|------|
| `/.env` | 403 (exists!) or 200 (exposed!) | **HIGH** — database creds, APP_KEY |
| `/.git/config` | 403 or 200 | **HIGH** — source code leak |
| `/composer.json` | 403 or 200 | **MEDIUM** — dependency info |
| `/artisan` | 200 | **HIGH** — Laravel CLI accessible |
| `/phpinfo.php` | 200 | **MEDIUM** — config disclosure |
| `/adminer.php` | 200 | **HIGH** — DB admin tool |
| `/phpMyAdmin` / `/pma` | 200 | **HIGH** — DB admin tool |

**PHP EOL Check:**
| Version | EOL Date | Status |
|---------|----------|--------|
| 7.4 | Nov 2022 | ❌ **EOL — no security patches** |
| 8.0 | Nov 2023 | ❌ EOL |
| 8.1 | Nov 2025 | ✅ Security support until Nov 2025 |
| 8.2+ | Active | ✅ Supported |

### 1.3 Security Headers Audit
Check these headers — all should be present in production:
- `Strict-Transport-Security` (HSTS) — prevents downgrade attacks
- `Content-Security-Policy` (CSP) — mitigates XSS
- `X-Frame-Options` — prevents clickjacking
- `X-Content-Type-Options: nosniff` — prevents MIME sniffing
- `Referrer-Policy` — controls referrer leakage

### 1.4 SQL Injection on Login Form
```python
payloads = [
    "' OR '1'='1",
    "' OR 1=1--",
    "' UNION SELECT NULL--",
    "admin' --",
    "\" OR \"1\"=\"1",
]
for p in payloads:
    # POST to /login with email=payload&password=test
    # If response != error -> possible SQLi
```

### 1.5 Path Enumeration
Test paths that indicate file existence even when blocked:
- **403** = file EXISTS but access denied (use different technique)
- **404** = file does not exist
- **200** = publicly accessible (may be sensitive)

Key paths to check:
```
/.env, /.git/config, /composer.json, /package.json,
/admin, /api, /graphql, /swagger, /api-docs,
/backup, /storage, /config, /debug, /log, /logs, /error_log,
/adminer.php, /phpMyAdmin, /pma, /phpinfo.php, /info.php,
/robots.txt, /sitemap.xml, /.htaccess, /.gitignore
```

### 1.6 CORS Testing
```bash
curl -sI -H "Origin: https://evil.com" https://target.com | grep "Access-Control"
# Should NOT return Access-Control-Allow-Origin: *
```

### 1.7 Rate Limiting Check
Send 10 rapid requests to login form. If no 429/rate-limit response:
```python
import time
for i in range(10):
    status = fetch("/admin/login", POST, data)
    time.sleep(0.1)
# No rate limit headers -> brute force possible
```

## Phase 2: Post-Auth (With Login)

Run these AFTER obtaining valid credentials.

### 2.1 IDOR Testing
After login, enumerate IDs in URL paths:
- `/admin/users/1` → try `/admin/users/2` (different user)
- `/api/invoices/123` → try `/api/invoices/124`
- Test with browser session, then try with another session

### 2.2 Privilege Escalation
- Test if low-priv user can access admin URLs directly
- Try role/user_type parameter tampering
- Test horizontal access (User A can see User B's data)

### 2.3 SQL Injection (Authenticated)
Test in search/filter forms, data tables, export features:
```sql
' OR '1'='1
' UNION SELECT table_name FROM information_schema.tables--
```

### 2.4 File Upload
If file upload exists:
- Test webshell upload (PHP/ASPX/JSP)
- Test SVG XSS
- Test path traversal in filename
- Test double extension bypass

### 2.5 Session Security
- Check HttpOnly, Secure, SameSite cookie flags
- Test session fixation (does session ID change after login?)
- Test session timeout

## Reporting

### Report Template for IT Team

```
# [App Name] — Security Assessment

**Tanggal:** [date]
**Tester:** [name]
**Tipe:** [Unauthorized / Authorized]

## 🔴 HIGH
### H1: [Title]
- **Deskripsi:** [what, where, how to reproduce]
- **Dampak:** [what attacker can do]
- **Saran:** [concrete fix]

## 🟡 MEDIUM
### M1: [Title]
- **Deskripsi:** ...
- **Dampak:** ...
- **Saran:** ...

## 🟢 INFO
- [additional observations]
```

### Priority Guidelines
| Level | Criteria |
|-------|----------|
| 🔴 HIGH | Data breach potential, RCE, auth bypass, EOL software |
| 🟡 MEDIUM | Security best practice violations, info disclosure |
| 🟢 INFO | Observations with minimal direct impact |

## Pitfalls
- **False positives on path enumeration**: 200 OK on `/config` might be SPA catch-all routing (all unknown paths return homepage). Verify by checking if response body contains actual config data vs generic HTML.
- **403 means file EXISTS**: If `.env` returns 403, it's protected by nginx but the file is there. If nginx config has a bypass, attacker could read it.
- **PHP EOL is not just "old"**: PHP 7.4 EOL means NO NEW SECURITY PATCHES EVER. Any CVE found after Nov 2022 will never be fixed.
- **ci_session cookie = CodeIgniter**: Not necessarily insecure, but CodeIgniter has had CVEs. Check version.

## Related Skills
- [[hunt-sqli]] — SQL injection deep dive
- [[hunt-idor]] — IDOR testing methodology
- [[hunt-file-upload]] — file upload bypasses
- [[hunt-auth-bypass]] — authentication bypass
- [[Bug Bounty Methodology]] — general testing approach
