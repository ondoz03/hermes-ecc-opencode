# Bounty Program Scope Discovery from Public Data

Even before registering for a bug bounty platform, you can discover full program scope, max payouts, safe harbor status, and in-scope assets from public data sources.

## Bugcrowd Data

The community-maintained `bounty-targets-data` repo contains the most comprehensive Bugcrowd program data:

```bash
curl -s "https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/main/data/bugcrowd_data.json"
```

Each program entry contains:
```json
{
  "name": "Indeed",
  "url": "https://bugcrowd.com/engagements/indeed",
  "allows_disclosure": false,
  "managed_by_bugcrowd": true,
  "safe_harbor": "full",
  "max_payout": 10000,
  "targets": {
    "in_scope": [
      { "type": "website", "name": "*.indeed.com" },
      { "type": "api", "name": "apis.indeed.com/graphql" }
    ]
  }
}
```

**Filter by program name:**
```bash
curl -s "https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/main/data/bugcrowd_data.json" \
  | jq '.[] | select(.name | test("indeed"; "i"))'
```

## HackerOne Data

The same repo has HackerOne data:
```bash
curl -s "https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/main/data/hackerone_data.json"
```

Note: HackerOne data is structured differently (uses `attributes` key).

## When to Use This

1. **Pre-registration recon** — Before creating accounts on Bugcrowd/HackerOne, you can already scope a target
2. **Scope comparison** — Find programs with the best payout-to-effort ratio
3. **Sibling domain discovery** — Programs often include sibling/acquisition domains you wouldn't find by subdomain enumeration alone (e.g., Indeed owns `resume.com`, `wowjobs.ca`)
4. **API target discovery** — The data explicitly lists API endpoints and GraphQL endpoints that may not be linked from public pages

## Usage in Recon Pipeline

Integrate into the 30-Minute Recon Protocol (minutes 0-5: Read Program Page):

```bash
TARGET="indeed"
PROGRAM=$(curl -s "https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/main/data/bugcrowd_data.json" \
  | jq ".[] | select(.name | test(\"$TARGET\"; \"i\"))")

echo "$PROGRAM" | jq '.targets.in_scope[].name' \
  | while read scope; do echo "Add to recon: $scope"; done
```

## Chain to Recon

Once you have program scope data:
1. Add all `*.domain.com` entries to your subdomain enumeration target list
2. Add API/GraphQL endpoints to your URL crawl targets
3. Note mobile apps (download and inspect APK/IPA for API keys)
4. Check sibling TLDs from scope (e.g., `indeed.tech`, `indeed.net`, `indeedflex.com`)
