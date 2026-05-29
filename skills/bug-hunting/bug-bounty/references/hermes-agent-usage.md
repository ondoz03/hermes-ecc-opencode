# Claude-BugHunter Skills di Hermes Agent

Skill bundle ini berasal dari [Claude-BugHunter](https://github.com/elementalsouls/Claude-BugHunter) — dirancang untuk **Claude Code** (`~/.claude/skills/`). Setelah di-copy ke Hermes Agent (`~/.hermes/skills/bug-hunting/`), ada beberapa perbedaan yang perlu diketahui.

## Yang BEDA dari Claude Code

| Fitur | Claude Code | Hermes Agent |
|---|---|---|
| Slash commands | `/hunt`, `/recon`, `/triage`, `/report`, `/chain`, `/autopilot` | **TIDAK ADA** — command ini cuma jalan di Claude Code |
| Instalasi | `~/.claude/skills/` | `~/.hermes/skills/bug-hunting/` |
| Trigger skill | Auto-load by keyword | Auto-load by keyword (sama) |
| Engagement scaffold | `hunt <target>` shell command | Manual — jalanin terminal commands sendiri |
| `cbh` CLI | Python CLI `cbh recon/hunt/triage/report` | Bisa jalanin manual via terminal |

## Cara Trigger Skill di Hermes

Sama seperti Claude Code — **mention aja apa yang di-hunt**:

| Bilang aja... | Skill yang auto-load |
|---|---|
| "lagi tes XSS" | `hunt-xss` (174 reports) |
| "cek IDOR" | `hunt-idor` (26 reports) |
| "tes SSRF" | `hunt-ssrf` (15 reports) |
| "SQL injection" | `hunt-sqli` |
| "file upload endpoint" | `hunt-file-upload` |
| "GraphQL introspection" | `hunt-graphql` |
| "RCE hunting" | `hunt-rce` (67 reports) |
| "OAuth flow" | `hunt-oauth` |
| "CI/CD, GitHub Actions" | CI/CD section di `bug-bounty` skill |
| "recon target.com" | `offensive-osint` |

## Frontmatter — Bedanya

Skill Claude-BugHunter pake frontmatter minimal:

```yaml
---
name: hunt-xss
description: Hunting skill for xss vulnerabilities...
sources: github, hackerone_public
report_count: 174
---
```

Hermes Agent standard pake frontmatter lebih lengkap:

```yaml
---
name: hunt-xss
description: "..."
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [xss, hunting, web]
    related_skills: [hunt-ssrf, hunt-csrf]
---
```

Keduanya **berfungsi** di Hermes — `name` dan `description` adalah satu-satunya field yang required. Field extra cuma kosmetik.

## Slash Commands — Alternatif

Claude-BugHunter punya 15 slash commands (`/recon`, `/hunt`, `/triage`, `/report`, `/chain`, `/autopilot`, dll). Ini **TIDAK JALAN** di Hermes Agent. Sebagai gantinya:

| Yang mau dilakukan | Alternatif |
|---|---|
| `/recon target.com` | Jalanin recon pipeline manual: `subfinder -d target.com`, `httpx`, dll |
| `/hunt target.com` | Load skill `bug-bounty` + `bb-methodology`, ikutin 5-phase workflow |
| `/triage` | Buka skill `triage-validation` dan jalanin 7-Question Gate manual |
| `/report` | Buka skill `report-writing` dan ikutin template |
| `/chain` | Load skill `bug-bounty` → bagian "Known A→B→C Chains" |
| `/validate` | Buka skill `triage-validation`, jalanin 7-Question Gate |
| `/autopilot` | Manual — pilih target dan jalankan prosesnya step by step |

## Workflow Adaptation

Claude-BugHunter 6-phase flow:

```
Claude Code:     Scope → Recon → Hunt → Validate → Capture → Report
                 (/hunt) (/recon)          (/triage)          (/report)

Hermes Agent:    Sama — tapi manual panggil skill yang relevan
                 Mention target → recon skill → hunt skill → triage-validation → report-writing
```

## Tools Reference

Tool-tool yang disebut di skill (nuclei, ffuf, subfinder, dll) jalan normal via terminal di Hermes. Gak ada bedanya.

## Ringkasan

- **Skill auto-load**: ✅ Sama — mention keyword, skill terload
- **Konten teknik**: ✅ Sama — 681 reports, payloads, bypass tables semua bisa dipake
- **Slash commands**: ❌ Gak jalan — ganti manual
- **Engagement scaffold**: ❌ Gak jalan — setup manual
- **Report templates**: ✅ Bisa dipake langsung
- **7-Question Gate**: ✅ Bisa diikutin manual
