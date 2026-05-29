# Indeed / Resume.com — GraphQL Introspection Case Study

**Target**: `https://www.resume.com/graph/api` (owned by Indeed Inc., in-scope for Indeed Bugcrowd program)

**Status**: Introspection fully enabled in production on a Gatsby 5.14.3 static site hosted via S3 + CloudFront (No Cloudflare).
**Discovered**: May 2026 via help center article analysis + JS bundle endpoint extraction.

---

## Discovery Flow

1. **Scope analysis**: From `bounty-targets-data` Bugcrowd data, Indeed's scope includes `resume.com` (and `wowjobs.ca`, `*.indeedflex.com`, `*.indeed.tech`, `*.indeed.net`).

2. **Subdomain scan**: `resume.com` resolves all subdomains (www, app, api, my, login, blog, careers, employer) to **AmazonS3 — No Cloudflare**:
   ```bash
   https://www.resume.com       200 [NoCF] AmazonS3
   https://app.resume.com       200 [NoCF] AmazonS3
   https://api.resume.com       200 [NoCF] AmazonS3
   https://my.resume.com        200 [NoCF] AmazonS3
   https://login.resume.com     200 [NoCF] AmazonS3
   https://help.resume.com      200 [NoCF] AmazonS3
   https://auth.resume.com      200 [NoCF] EC2 (returns `{"status":"ok"}`)
   ```

3. **JS bundle analysis**: The HTML page source reveals it's a **Gatsby 5.14.3** app:
   ```html
   <meta name="generator" content="Gatsby 5.14.3"/>
   ```
   JS bundles: `/webpack-runtime-*.js`, `/framework-*.js`, `/app-*.js` (726KB).
   Grep in the app bundle for API endpoints reveals:
   ```
   https://auth.resume.com
   https://www.resume.com/graph/api
   ```

4. **GraphQL introspection test**:
   ```bash
   curl -s "https://www.resume.com/graph/api" -X POST \
     -H "Content-Type: application/json" \
     -d '{"query":"{ __typename }"}'
   # → {"data":{"__typename":"Query"}}
   
   curl -s "https://www.resume.com/graph/api" -X POST \
     -H "Content-Type: application/json" \
     -d '{"query":"{__schema{queryType{name}mutationType{name}types{name kind fields{name type{name kind ofType{name kind}}}}}}"}'
   # → Full schema!
   ```

> **Note**: The GraphQL endpoint is **not** at `/graphql` but at `/graph/api` — always check alternative paths when the standard `/graphql` doesn't exist.

---

## Schema Overview

### Query Type Fields
| Field | Return Type | Description |
|-------|-------------|-------------|
| `health` | ResponseStatus | Health check |
| `User` | User | Current user data |
| `Resume` | Resume | Current user's resume |
| `Autocomplete` | Autocomplete | Job title / company / skill / location suggestions |
| `Suggestions` | Suggestions | AI-powered text generation |
| `Counter` | Counter | Platform stats (total resumes, registered users) |
| `CoverLetter` | CoverLetter | Cover letter data |
| `getProctorGroups` | ProctorGroupsResponse | A/B test groups |

### Mutation Type Fields
| Field | Return Type | Description |
|-------|-------------|-------------|
| `response` | ResponseStatus | Generic response |
| `User` | User | User mutations |
| `Resume` | Resume | Resume mutations |
| `Log` | Log | Analytics logging |
| `CoverLetter` | CoverLetter | Cover letter mutations |

---

## Critical Objects

### User (43 fields)
```graphql
type User {
  id: ID
  accountEmail: String
  firstName: String
  lastName: String
  profileEmail: String
  username: String
  address: String
  city: String
  state: String
  zip: String
  country: String
  phone: String
  # + 32 more fields
}
```

### Resume (91+ fields)
```graphql
type Resume {
  id: ID
  userId: String
  createdDate: Int
  updatedDate: Int
  wordCount: Int
  contactDetails: ContactDetails  # firstName, lastName, email, phone, address, city, zip, country, photoUrl, headline, linkedinUrl, websiteUrl
  sections: [Section]            # resume sections with rich content
  template: String
  # + 85 more fields
}
```

### IndeedResponse (HIGH VALUE — auth tokens!)
```graphql
type IndeedResponse {
  magicToken: String
  indeedEmail: String
  accessToken: String
  refreshToken: String
}
```

### JobSeekerProfile — Indeed Integration
```graphql
type JobSeekerProfile {
  profile: IndeedProfile
}
type IndeedProfile {
  resume: IndeedProfileResume
}
type IndeedProfileResume {
  id: ID
  source: String
  visibility: String
}
```

### MagicToken — Auth Bypass?
```graphql
type MagicToken {
  magicToken: String
}
```

### Suggestions — AI Features (Prompt Injection / SSRF?)
```graphql
type Suggestions {
  skills: StringArray
  AllJobTitleWithExamples: StringArray
  EmploymentText: StringArray
  EducationText: StringArray
  SummaryText: StringArray
  AIExperienceImprover: StringArray
  tweakify: TweakifyResponse
  generateCoverletter: TweakifyResponse
}
```

### Autocomplete — Public Data Enumeration
```graphql
type Autocomplete {
  jobTitle: StringArray
  companyName: StringArray
  skillName: StringArray
  location: LocationArray
}
```

---

## Auth Architecture

### Indeed OAuth Client ID (Found via JS Bundle)

From the OAuth page component (`/component---src-pages-indeed-oauth-index-tsx-*.js`):
```javascript
const t=i();
return `https://secure.indeed.com/oauth/v2/authorize?
  client_id=24cf570e641a1fe08a0500e36aa840ab24c959b92ba1
  &response_type=code
  &state=${t}
  &scope=email+employer_access+offline_access
  &from=${e}`
```

| Parameter | Value |
|-----------|-------|
| **Client ID** | `24cf570e641a1fe08a0500e36aa840ab24c959b92ba1` |
| **Auth URL** | `https://secure.indeed.com/oauth/v2/authorize` |
| **Response type** | `code` |
| **Scope** | `email + employer_access + offline_access` |
| **Token storage** | localStorage keys: `accessToken`, `indeedEmail` |

The OAuth page is at `https://www.resume.com/indeed/oauth/`. After authorization, the code is exchanged server-side for tokens, which are stored in localStorage via `localStorage.setItem(m.Xh, t.accessToken)`.

### Guest Session Behavior

When visiting the resume builder at `/resume/builder/`, a **guest user** is created automatically:
```json
{
  "resume_user": "{\"id\":\"7e9858c8-1942-4644-b84a-2819b5a01e91\",\"createdDate\":1779874561,\"__typename\":\"User\"}",
  "isUser": "true"
}
```

The session is maintained via **AWS Application Load Balancer cookies** (`AWSALB`, `AWSALBCORS`) set by the S3/CloudFront origin.

### Practical Auth Testing Results

| Query | Auth Required | Guest Session Result |
|-------|:---:|:---:|
| `{ __typename }` | None | ✅ `{"data":{"__typename":"Query"}}` |
| `{ Suggestions { skills { results } } }` | **PUBLIC** | ✅ Returns skill suggestions |
| `{ Autocomplete { ... } }` | **PUBLIC** | ✅ Returns `"An unknown error occurred"` (needs search term args) |
| `{ Counter { total_resumes } }` | Session | Returns null (guest) |
| `{ health { success } }` | Session | Returns null |
| `{ User { id accountEmail } }` | Session | ✅ Returns null fields (guest user has no data) |
| `{ User(id: "...") { id } }` | — | `"Unknown argument \\"id\\" on field \\"Query.User\\""` |
| `{ Resume { id } }` | JWT | ❌ `"No JWT was supplied in request"` |
| `{ CoverLetter { id } }` | JWT | ❌ `"No JWT was supplied in request"` |

---

## Attack Surface Analysis

### 1. Introspection Enabled (Root Cause #4 in hunt-graphql)
Default Gatsby/Apollo settings left introspection on in production. This reveals the entire data model including:
- User PII fields (43 fields)
- Resume contact details with phone/email/address
- Indeed OAuth tokens (accessToken, refreshToken)
- AI prompt generation endpoints

### 2. Indeed OAuth Client ID Hardcoded in JS Bundle
The Indeed OAuth client ID and authorization endpoint are hardcoded in the publicly served JS bundle. This enables:
- **CSRF-style attacks** — craft OAuth authorize URLs with a victim's session
- **Scope abuse** — `employer_access` scope is included (can it be expanded?)
- **State parameter prediction** — `state` is generated from `Math.random().toString()` — weak entropy (see config)
- **Token leakage** — accessToken is stored in localStorage (accessible to XSS)

### 3. No IDOR on User Query (Safely Guarded)
The `User` query in Query type takes **no `id` argument** — it returns only the current user based on session/JWT. This means:
- `User(id: "xxx")` → `"Unknown argument \"id\""` — safe, no IDOR
- `User` → returns current session user's data (null for guests, real data for logged-in)
- The IDOR risk shifts to **mutations** that might accept user IDs (check `Mutation.User`, `Mutation.Resume`)

### 4. Resume Query Requires JWT (Hard Auth)
`Resume` query returns `"No JWT was supplied in request"` without authentication. No IDOR surface on the direct query.

### 5. IndeedResponse Token Exposure
If `IndeedResponse` can be queried through a mutation chain:
```graphql
mutation {
  User {
    indeedResponse {
      accessToken
      refreshToken
      indeedEmail
    }
  }
}
```
This would give direct access to Indeed.com with the user's identity. **Check if login mutations return IndeedResponse.**

### 6. AI Feature Abuse
- `Suggestions.tweakify` and `Suggestions.generateCoverletter` are AI text generation endpoints
- `AIExperienceImprover` returns empty `{results: []}` — needs input args
- Potential for **prompt injection** in the input payload
- Potential for **SSRF** if the AI model fetches external content
- Check for rate limits on these endpoints

### 7. Autocomplete as Recon Primitive
The `Autocomplete` field may accept search queries that reveal:
- Company names (enumerate competitors/partners)
- Skill names (internal technologies)
- Location data (office addresses)

```graphql
{ Autocomplete { companyName { results } } }
```
Note: Returns `"An unknown error occurred"` without a search term argument.

### 8. Public Counter Data
```graphql
{ Counter { total_resumes resumes_uploaded_today registered_users } }
```
Public stats — not a vulnerability but useful for impact framing.

### 9. Suggestions API (Public — No Auth Needed)
```graphql
# Skills suggestions — works without auth
{ Suggestions { skills { results } } }
```
Returns 14+ skill names (Customer service, Food service, Communication skills, etc.).

---

## Chain Opportunities

| Chain | Description |
|-------|-------------|
| Introspection → IDOR | Full schema → find unauthenticated User/Resume queries → PII of all users |
| Introspection → Token Theft | Find mutation path to Indeed accessToken → Indeed.com account takeover |
| AI Suggestions → Prompt Injection | Inject via resume text → AI generates malicious content |
| Autocomplete → Enumeration | Brute-force company/skill/location names → internal business intel |
| MagicToken → Auth Bypass | Generate valid magic tokens without credentials → full account access |

---

## Remediation

1. Disable GraphQL introspection in production (`introspection: false` in Apollo, `GRAPHQL_INTROSPECTION=False` in Strawberry/Graphene)
2. Implement field-level authorization on `User`, `Resume`, `IndeedResponse` types
3. Rate-limit `Suggestions` endpoints (AI API costs)
4. Review `IndeedResponse` mutations for proper OAuth scope validation

---

## References

- Bugcrowd Indeed program: `bounty-targets-data/data/bugcrowd_data.json`
- Gatsby 5.14.3: https://www.gatsbyjs.com/docs/
- Indeed Bug Bounty Program: https://bugcrowd.com/engagements/indeed
