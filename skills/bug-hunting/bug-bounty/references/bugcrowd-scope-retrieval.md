# Bugcrowd Scope Retrieval

Bugcrowd does not expose a public GraphQL API like HackerOne. Use these sources instead.

## 1. Bounty Targets Data (arkadiyt)

```bash
curl -s "https://raw.githubusercontent.com/arkadiyt/bounty-targets-data/master/data/bugcrowd_data.json" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
for p in data:
    name = (p.get('name') or '').lower()
    if 'targetname' in name:
        scopes = p.get('targets', {}).get('in_scope', [])
        for s in scopes:
            print(f\"[{s.get('type','?')}] {s.get('asset_identifier','?')}\")
" 2>/dev/null
```

**Limitations:** Asset identifiers may appear as `?` in the data — the actual scope is available on the Bugcrowd program page.

## 2. Bugcrowd Program Page

Visit `https://bugcrowd.com/engagements/PROGRAM_NAME` — scope information including asset types (website, API, mobile) and eligible-for-bounty status is publicly visible. The page also shows:
- Program description and rules
- Testing requirements (e.g., `@bugcrowdninja.com` email)
- Ground rules
- Scope rating (1-4)

## 3. Crowdstream API (Public Findings)

```bash
curl -s "https://bugcrowd.com/crowdstream.json?page=1&sort=recent&program=PROGRAM_NAME" \
  | jq '.crowdstream[] | {title, severity, submitted_at}'
```

Note: May require authentication or return empty if no public disclosures exist.

## 4. Testing Requirement

Many Bugcrowd programs require `@bugcrowdninja.com` email addresses. Request additional aliases via the credential request button on the program page. Include `bugbounty` in all text fields (company title, user agent string, etc.) as per program rules.

## 5. Disclosed Reports

Bugcrowd disclosures are visible on the program page's "Disclosures" tab. Unlike HackerOne's Hacktivity API, Bugcrowd does not expose a simple JSON endpoint for disclosed reports — browse manually or use the crowdstream.
