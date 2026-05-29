# Bugcrowd & Target-Specific Recon Patterns

## Bugcrowd Program Recon

Unlike HackerOne, Bugcrowd's public data has different patterns:

- **Scope source**: `arkadiyt/bounty-targets-data/data/bugcrowd_data.json` — but asset_identifiers may be `null`/`"?"` in the raw JSON. The real scope requires checking the Bugcrowd program page directly.
- **Program page**: `https://bugcrowd.com/engagements/<handle>` — shows scope rating, testing requirements, ground rules publicly (no login needed).
- **Testing requirement**: Many Bugcrowd programs require accounts with `@bugcrowdninja.com` emails. These are provisioned through the platform — you request them via the "credential request" button on the program page.
- **Disclosed reports**: Crowdstream (`/crowdstream.json`) often requires authentication. Alternative: search program name on HackerOne Hacktivity or use Google dorks (`site:hackerone.com "Indeed" bug bounty`).

## Indeed Recon (Bugcrowd Target)

### DNS Profile
```
indeed.com          162.159.129.67    Cloudflare WAF
www.indeed.com      162.159.129.67    Cloudflare WAF
secure.indeed.com   162.159.129.67    Cloudflare WAF
apis.indeed.com     104.18.35.224     Cloudflare
support.indeed.com  216.198.54.11     indeed.zendesk.com (NOT Cloudflare)
assets.indeed.com   146.75.47.10      Akamai (NOT Cloudflare)
media.indeed.com    23.219.204.176    Non-CF (Akamai)
```

**Key insight**: `support.indeed.com` = `indeed.zendesk.com` — Help Center behind Zendesk, NOT fully behind Cloudflare WAF even though cf-ray header appears. This creates an alternative attack surface.

### Zendesk Public API (Unauthenticated)

Zendesk Help Centers expose public API endpoints that work without auth:

| Endpoint | Purpose |
|----------|---------|
| `/api/v2/help_center/articles.json?per_page=3` | List articles (paginated) |
| `/api/v2/help_center/categories.json` | List categories |
| `/api/v2/help_center/sections.json` | List sections |
| `/api/v2/help_center/articles/{id}.json` | Single article body |
| `/embeddable/config` | Widget config (brand, colors, host mapping) |
| `/api/v2/categories/{id}/articles.json` | Articles per category |
| `/api/v2/categories/{id}/sections.json` | Sections per category |

Admin endpoints (`/api/v2/tickets`, `/api/v2/search`, `/api/v2/users`) return 401 without auth — correctly locked down.

### Zendesk Article Body Extraction

Articles returned by the API include `body` field with full HTML content. This can reveal:
- Internal tools/endpoints mentioned in documentation
- API integration details (e.g., "Indeed App on ChatGPT")
- Feature descriptions useful for attack surface mapping

### ChatGPT Integration Angle

When a target has a ChatGPT integration (noted in Zendesk articles), test prompt injection vectors:

1. **Direct injection**: Feed instructions that override the ChatGPT app's system prompt
2. **Indirect injection**: Reference URLs the ChatGPT app might fetch that contain hidden instructions
3. **System prompt extraction**: Ask the app to repeat its configuration
4. **Data exfiltration**: Query for data the integration can access but shouldn't expose

This can be tested WITHOUT a Bugcrowd account — just through ChatGPT.

### Cloudflare Bypass Strategy

When main domains return 403 Cloudflare WAF:
1. **Identify non-CF subdomains** — use `host sub.target.com` and check for non-Cloudflare IPs (Akamai, Fastly, AWS, Zendesk, etc.)
2. **Check assets/CDN subdomains** — `assets.*`, `media.*`, `static.*` often bypass WAF
3. **Pivot to Zendesk/helpdesk** — Zendesk instances often have different security posture
4. **Check GitHub repos** — many Bugcrowd targets include `github.com/OrgName/*` in scope for CI/CD pipeline attacks

### Attack Vector Priority for Indeed

1. **ChatGPT injection** (no account needed)
2. **AI Recruiter Questions** — LLM prompt injection via candidate answers
3. **Glassdoor + Indeed OAuth** — "One Login" cross-platform account takeover potential
4. **Bot mitigation bypass** — security check bypass testing
5. **Zendesk IDOR** — enumerated article IDs for access control testing

## Zendesk Help Center as General Attack Surface

When ANY target uses Zendesk (detectable via `x-zendesk-*` response headers or `*.zendesk.com` CNAME), test:

1. **Public API access**: Help Center API is typically public by design — verify what data it exposes
2. **Article enumeration**: Sequential article IDs may reveal hidden/internal articles
3. **Category/section information disclosure**: Category names reveal org structure
4. **Widget config**: `/embeddable/config` reveals brand info, channel IDs
5. **Admin endpoint 401 confirmation**: Important negative finding — confirms auth is working on admin paths

## Bugcrowd-Specific Notes

- Bugcrowd program data from bounty-targets-data has a different schema than HackerOne. In-scope items have `type` (website/api/android/ios/other) and `asset_identifier` fields, but identifiers may be `null` in the mirror data.
- Bugcrowd programs require registering on the Bugcrowd platform and accepting the program's terms before testing.
- Some Bugcrowd programs restrict testing to community-contributed methodologies or require explicit approval for certain test types.
- Unlike HackerOne's Hacktivity (public disclosed reports), Bugcrowd Crowdstream requires authentication for program-specific filtered views.
