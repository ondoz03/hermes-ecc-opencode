# Zendesk Recon Case Studies

## Indeed — 95 Ticket Forms Exposed via Content-Type Bypass

**Target**: `indeed.zendesk.com` (CNAME: `support.indeed.com` → `indeed.zendesk.com`)

### Discovery Flow

1. **Help Center API check** (public, no auth):
   ```bash
   curl -s "https://indeed.zendesk.com/api/v2/help_center/categories.json"
   ```
   → 1 category: "Jobseeker - US", 9 sections (Account, Profile & Resume, Applying for a Job, Job Search Tips, My Jobs, Messages, About Indeed, Company Pages & Reviews, Technical Support)

2. **Ticket forms probe** (415 → 200 bypass):
   ```bash
   # Without Content-Type → 415
   curl -s "https://indeed.zendesk.com/api/v2/ticket_forms"
   
   # With Content-Type: application/json → 200!
   curl -s "https://indeed.zendesk.com/api/v2/ticket_forms" \
     -H "Content-Type: application/json"
   ```
   → **95 ticket forms** exposed including internal partner workflows

3. **Ticket fields** (requires auth):
   ```bash
   curl -s "https://indeed.zendesk.com/api/v2/ticket_fields" \
     -H "Content-Type: application/json"
   ```
   → `{"error":"Couldn't authenticate you"}` (401)

### Key Findings

| Finding | Detail |
|---|---|
| Total forms | 95 |
| Active forms | ~20 (active:true) |
| Internal forms | "Visibility Appeal", "Testing", "Quality Appeals", "PFG - Troubleshooting" |
| Partner workflows | Camping World, Albertsons, Walmart, Amazon WFS, Port of Rotterdam, Resume.com, Simply Hired, Nurseful |
| Unrestricted forms | `restricted_brand_ids: []` — some forms have no brand restriction |
| Field IDs exposed | Internal field IDs (21791994, 21792004, 22745534...) reveal data model |
| Conditional logic | `end_user_conditions` with `parent_field_id` + `value` routing |
| Template injection surface | `{{dc.my_indeed_form}}`, `{{dc.form_resume}}` placeholders |
| Search API | Requires auth (401): `/api/v2/search.json?query=...` |

### Interesting Articles (via Zendesk API)

**Article: "About the Indeed App on ChatGPT"** (#43197872743565)
- Users invoke via `@Indeed` in ChatGPT
- ChatGPT gets: Name, General location, Profile summary, Work experience, Education, Skills, Job preferences
- Indeed claims: "We don't share your personal details with OpenAI"
- **Attack vector**: Prompt injection via Indeed profile data → ChatGPT misbehavior
- Article last updated: 2026-05-22

**Article: "About AI Recruiter Questions"** (#42787723284749)
- Employers create open-ended LLM-powered questions post-application
- Supports: Chat (text), Audio, Video formats
- Professional Healthcare License Verification via third-party
- **Attack vector**: Malicious employer questions → LLM prompt injection in answer processing
- Article last updated: 2026-05-27

### Full Subdomain Scan (71 Reachable)

```bash
# ─── Indeed.com (Cloudflare) ─────────────────────
www.indeed.com             200 CF
secure.indeed.com          200 CF   (CTK, SURF, google_n, apple_n cookies)
my.indeed.com              200 CF
employers.indeed.com       200 CF
ads.indeed.com             200 CF   (CO cookie)
accounts.indeed.com        200 CF   (login page, CTK/SURF cookies)
sso.indeed.com             200 CF   (WorkOS JSON response!)
support.indeed.com         200 CF   (Zendesk proxy)
help.indeed.com            200 CF
careers.indeed.com         200 CF
developer.indeed.com       200 CF   (CSRF cookie exposed)
partners.indeed.com        200 CF
indeed.com                 200 CF
resumes.indeed.com         403 CF
hire.indeed.com            200 CF
wiki.indeed.com            200 CF   (custom session cookie `CF_Session`)
apply.indeed.com           403 CF

# ─── No Cloudflare (Higher Attack Surface) ─────
indeedhi.re                200 NoCF  (Bitly URL shortener)
media.indeed.com           404 NoCF  (possible CDN takeover)

# ─── Country Subdomains (All CF) ────────────────
# 200: uk, de, fr, jp, au, br, in, es, ch, be, at, no, dk, fi
#       cn, nz, sg, hk, mx, lu, pt, il, ae, tr, gr, cz
#       hu, se, pl, cl, co, my, ph, th, kr, tw, pk, eg
#       ma, it, ca, nl, ie, za, ro, ar, vn, id, ng
# 403: nl, ie, it, za, ro, ar, vn, id, ng

# ─── Indeed Other Domains ───────────────────────
indeed.ch                   200 CF
indeed.de                   200 CF
```

### Indeed GraphQL API (`apis.indeed.com/graphql`)

```bash
curl -s "https://apis.indeed.com/graphql" -X POST \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __typename }"}'
# → {"data":null,"errors":[{"message":"An API Key is required.",...}]}
```

- Returns `"An API Key is required."` — requires authentication
- Response includes `indeed-tracking-key` header and `x-envoy-decorator-operation: passport_auth_proxy_ingress` (uses Envoy proxy + Passport auth)
- **No known API key** — potential sources: mobile apps APK/IPA, Chrome extension, developer portal docs
- Not in scope list explicitly, but covered by `apis.indeed.com` wildcard

### Indeed Bugcrowd Program Details

From `bounty-targets-data`:

```
Program:  Indeed
Max Payout: $10,000
Safe Harbor: full
Disclosure: false (not allowed)
Managed by: Bugcrowd

In-Scope (17 targets):
  *.indeed.com
  *.indeedflex.com
  apis.indeed.com/graphql        ← GraphQL!
  *.indeed.tech
  *.indeed.net
  resume.com                     ← Owned sub-target
  wowjobs.ca
  Career Scout
  Mobile apps (Android + iOS)
  Chrome Extension (Indeed Recruiter)
  "Any host/web property owned by Indeed"
```

Key: `resume.com` and `wowjobs.ca` are both in-scope as sibling properties.

### Chain Opportunities

1. Zendesk ticket forms exposure → partner workflow abuse (IDOR on ticket submission)
2. ChatGPT integration → prompt injection via Indeed profile → data exfil or tool misuse
3. AI Recruiter → prompt injection in employer questions → LLM answer manipulation
4. OAuth chain: Glassdoor + Indeed One Login → credential theft or account linking abuse
5. Bot Mitigation bypass → automated application submission
