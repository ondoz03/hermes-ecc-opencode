# Indeed Bug Bounty Recon Notes

**Platform:** Bugcrowd (not HackerOne) — https://bugcrowd.com/engagements/indeed  
**Status:** Ongoing since Jan 26, 2015  
**Scope rating:** 4/4  
**Testing requirement:** Must use @bugcrowdninja.com email addresses. Include "bugbounty" in all text fields including User-Agent.

## Recon Results

### DNS Mapping
| Domain | IP | CDN |
|--------|----|-----|
| indeed.com | 162.159.129.67 / 162.159.130.67 | Cloudflare |
| www.indeed.com | 162.159.129.67 / 162.159.130.67 | Cloudflare |
| secure.indeed.com | 162.159.129.67 / 162.159.130.67 | Cloudflare |
| apis.indeed.com | 104.18.35.224 / 172.64.152.32 | Cloudflare |
| employer.indeed.com | 162.159.129.67 / 162.159.130.67 | Cloudflare |
| support.indeed.com | CNAME → indeed.zendesk.com (216.198.54.11) | Cloudflare + Zendesk |
| accounts.indeed.com | 162.159.129.67 / 162.159.130.67 | Cloudflare |
| sso.indeed.com | 172.64.146.8 | Cloudflare |
| assets.indeed.com | 146.75.47.10 | Not Cloudflare (Fastly/Akamai) |
| media.indeed.com | 23.219.204.176 | Not Cloudflare (Akamai) — returns 404 |

### Zendesk (indeed.zendesk.com)
- Help Center API publik accessible: categories, sections, articles all readable without auth
- 9 sections: Account, Profile & Resume, Applying, Job Search Tips, My Jobs, Messages, About Indeed, Company Pages, Technical Support
- Widget config publik: `/embeddable/config` returns brand info
- Admin/ticket API endpoints require auth (401)

### Interesting Attack Surfaces
1. **ChatGPT Integration** — "Indeed App on ChatGPT" article suggests an OAuth/API integration → prompt injection angle
2. **AI Recruiter Questions** — LLM-powered feature → prompt injection, indirect injection
3. **Glassdoor + Indeed One Login** — Account merging/SSO → OAuth chain potential
4. **Bot Mitigation Check** — Security feature, possible bypass testing
5. **Indeed Messages** — Internal messaging system → IDOR potential

### Notes
- Cloudflare WAF returns 403 on all main subdomains when probed without proper headers/UA
- `support.indeed.com` is the gateway to Zendesk (CNAME indeed.zendesk.com)
- Bugcrowd program requires specific test accounts (@bugcrowdninja.com)
