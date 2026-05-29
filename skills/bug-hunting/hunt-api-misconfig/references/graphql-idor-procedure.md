# GraphQL IDOR & Bug Bounty Recon Procedure

## Systematic GraphQL IDOR Testing Workflow

### Step 1 — Endpoint Discovery
Check standard paths: `/graphql`, `/graph/api`, `/api/graphql`, `/v1/graphql`, `/query`
Also check subdomain siblings (same auth backend often reused).

### Step 2 — Introspection
Full introspection request (compact form to avoid timeouts):
```graphql
{ __schema { queryType { fields { name args { name type { name kind ofType { name kind } } } type { name kind ofType { name kind } } } } mutationType { fields { name args { name type { name kind ofType { name kind } } } type { name kind ofType { name kind } } } } } }
```

Parse output to identify:
- **Query types** — what data can be read
- **Mutation types** — what data can be written
- **Input types** — what parameters mutations accept
- **Fields on each type** — especially sensitive ones (email, token, password, phone, address)

### Step 3 — Auth Boundary Map
Test each query/mutation at three auth levels:

| Test | Command |
|---|---|
| No auth | `curl` with no cookies/headers |
| Session | `curl` with browser cookies (AWSALB, _gid, etc.) |
| JWT | `curl` with `Authorization: Bearer <token>` |

Note which fields return data at each level. Mark the auth boundary precisely — a query that partially works at a lower auth level is still interesting.

### Step 4 — IDOR Probe
For queries/mutations that accept an `id` argument:
1. Get your own user/resource ID (from localStorage, API response, or registration)
2. Query with your own ID → confirm response shape
3. Query with a random non-existent UUID → compare
4. Query with sequential IDs (1, 2, 3...) or other users' IDs (if guessable)
5. For mutations named after types (e.g. `User(id:)`), test if they create-on-write or just look up

### Step 5 — JS Bundle Deep Dive
For Gatsby/React SPAs:
1. Download main JS bundle and webpack runtime
2. Extract route paths: `component---src-pages-{name}-tsx`
3. Download each page chunk
4. Search for: OAuth client IDs, API keys, GraphQL operation names, hidden endpoints
5. Test discovered OAuth flows for CSRF, redirect URI bypass, PKCE gaps

### Step 6 — AI Feature Testing
If Suggestions/AI/autocomplete endpoints are public:
1. Test with crafted input for prompt injection
2. Test with large payloads for DoS
3. Test with special characters for error disclosure
4. Check if AI features make external API calls (SSRF vector)

## Resume.com / Indeed — Case-Specific Notes

### GraphQL API
- **Endpoint**: `https://www.resume.com/graph/api`
- **Method**: POST, Content-Type: application/json
- **Auth split**: User query = session cookies (no JWT), Resume = JWT required
- **Guest session ID**: Auto-generated in localStorage (`resume_user.id`) when visiting builder page
- **Rate limiting**: Heavy introspection queries may trigger timeout — use focused queries

### Indeed OAuth for Resume.com
- **Auth endpoint**: `https://secure.indeed.com/oauth/v2/authorize`
- **Client ID**: `24cf570e641a1fe08a0500e36aa840ab24c959b92ba1`
- **Scope**: `email + employer_access + offline_access`
- **Response type**: `code`
- **Token storage**: AccessToken in localStorage after OAuth callback
- **Page**: `/indeed/oauth/` handles the OAuth redirect

### Indeed GraphQL (apis.indeed.com/graphql)
- Requires API key: `"An API Key is required."`
- Uses Envoy proxy (`x-envoy-decorator-operation: passport_auth_proxy_ingress`)
- API key source unknown — check mobile apps (APK/IPA) and Chrome extension

### Zendesk Ticket Forms
- **Instance**: `indeed.zendesk.com` (CNAME: `support.indeed.com`)
- **Bypass**: Add `Content-Type: application/json` header to get 200 instead of 415
- **95 forms discovered** including internal partner workflows
- **Ticket fields** at `/api/v2/ticket_fields` require auth (401)

### Bugcrowd Program
- Max: $10,000
- Full safe harbor
- Disclosure not allowed
- 17 in-scope targets including all subdomains, apps, and "any property owned by Indeed"
