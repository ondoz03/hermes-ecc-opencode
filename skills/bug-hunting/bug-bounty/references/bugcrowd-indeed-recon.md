# Bugcrowd Target Recon + Zendesk API Workflow

Systematic approach for targets on **Bugcrowd** (not HackerOne), especially when Cloudflare WAF blocks direct probing.

## Bugcrowd vs HackerOne Recon Differences

| Aspect | HackerOne | Bugcrowd |
|--------|-----------|----------|
| Scope source | `bounty-targets-data` JSON | `bounty-targets-data` JSON (different format — asset_identifier may be `"?"`) |
| Disclosed reports | `hacktivity` page | `crowdstream.json?program=X` API |
| Testing requirement | Usually self-service | Often requires `@bugcrowdninja.com` email |
| Program page | `/PROGRAM` | `/engagements/PROGRAM` |

## Cloudflare WAF Pivot Strategy

When all main domains return 403 (Cloudflare):

1. **Zendesk pivot** — Check if target uses Zendesk for support (`host support.target.com` → CNAME to *.zendesk.com?)
2. **Non-CDN subdomains** — DNS brute for IPs without `cf-ray` header
3. **CDN assets** — `assets.*`, `media.*`, `static.*` often bypass main WAF
4. **Third-party integrations** — `support.*`, `help.*`, `status.*` use different infra

## Zendesk API Enumeration (No Auth)

| Endpoint | Purpose |
|----------|---------|
| `/api/v2/help_center/categories.json` | List categories |
| `/api/v2/help_center/articles.json?per_page=100` | List articles |
| `/api/v2/help_center/articles/{id}.json` | Article body |
| `/embeddable/config` | Widget config |
| `/api/v2/help_center/sections.json` | List sections |

### Rate Limiting Check
No `X-Rate-Limit` headers = no rate limiting = enumerate freely.

### Article Scan Keywords
`security`, `api`, `internal`, `admin`, `password`, `token`, `credential`, `secret`, `vulnerability`, `sso`, `oauth`, `webhook`, `privacy`

### IDOR Test
Article IDs are sequential integers — enumerate via `articles/{id}.json`.

## Target-Specific: Indeed

- **Main**: Cloudflare (162.159.x.x) — 403 on everything
- **Zendesk pivot**: `support.indeed.com` = `indeed.zendesk.com` (216.198.x.x) — API publik
- **Non-CF**: `assets.indeed.com` (Akamai), `media.indeed.com` (Akamai)
- **Interesting features**: ChatGPT App, AI Recruiter, Glassdoor OAuth, Bot Mitigation
