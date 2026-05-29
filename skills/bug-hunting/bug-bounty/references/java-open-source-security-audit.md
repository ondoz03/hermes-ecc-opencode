# Java Open-Source Security Audit

Reconnaissance & vulnerability discovery methodology for Java open-source projects (Maven/Gradle).

## Quick Assessment (5 min)

```bash
# Dependencies & versions
curl -s https://raw.githubusercontent.com/OWNER/REPO/main/pom.xml | grep -E '<artifactId>|<version>'

# Security policy
curl -s https://raw.githubusercontent.com/OWNER/REPO/main/SECURITY.md

# Recent fixes
curl -s "https://api.github.com/repos/OWNER/REPO/commits?per_page=10" | \
  python3 -c "import json,sys; [print(c['commit']['message'].split(chr(10))[0]) for c in json.load(sys.stdin) if any(k in c['commit']['message'].lower() for k in ['fix','secur','vuln','cve','patch'])]"

# Open issues
curl -s "https://api.github.com/repos/OWNER/REPO/issues?state=open&per_page=5" | \
  python3 -c "import json,sys; [print(f'#{i[\"number\"]}: {i[\"title\"]} [{chr(44).join(l[\"name\"] for l in i.get(\"labels\",[]))}]') for i in json.load(sys.stdin)]"
```

## High-Risk Dependencies

When scanning `pom.xml` / `build.gradle`, flag these for deeper review:

| Dependency | Risk | Why |
|------------|------|-----|
| **Velocity Engine** (`velocity-engine-core`) | 🔴 SSTI → RCE | Template injection if user input reaches templates |
| **Docker Java** (`docker-java-*`) | 🔴 RCE / Container escape | Docker API calls — command injection in image/container names |
| **Protobuf** (`protobuf-java`) | 🟡 Deserialization | Malformed protobuf messages can trigger OOM or RCE |
| **JSONata** (`jsonata`) | 🟡 Expression injection | JSON query expression language — injection via crafted input |
| **SnakeYAML** (`snakeyaml`) | 🔴 RCE | `yaml.load()` on untrusted input = arbitrary code execution |
| **XStream** (`xstream`) | 🔴 RCE | Known deserialization CVEs |
| **Log4j** (`log4j-core`) | 🔴 RCE | < 2.17.0 = Log4Shell |
| **Jackson** (`jackson-*`) | 🟡 OOM / RCE | Polymorphic deserialization gadgets |
| **Thymeleaf** / **Freemarker** | 🔴 SSTI | Template injection |

## Attack Surface by Component

### AWS Service Emulators
- **S3**: File upload → path traversal, XML parsing → XXE, bucket policy injection
- **Lambda**: Container lifecycle → command injection, Docker escape
- **EC2**: Network interface parsing → SSRF, security group misconfig
- **DynamoDB**: Expression evaluation → injection
- **SQS/SNS**: Message body → stored XSS, deserialization
- **CloudFormation**: Template parsing → SSTI, SSRF via custom resources
- **Secrets Manager / SSM**: Credential storage → exposure

### Infrastructure
- **HTTP server** (Jetty/Netty/Undertow): Request smuggling, path normalization
- **Docker client**: Container name/command injection
- **Database**: SQLite, H2, PostgreSQL — SQL injection if queries are dynamic

## Authentication Testing

Java AWS emulators typically accept any non-empty credentials (no real auth). This means:

```python
# All of these "work" as credentials
AWS_ACCESS_KEY_ID=test
AWS_SECRET_ACCESS_KEY=test
AWS_SECRET_ACCESS_KEY=anything
```

**Testing approach:** Since there's no real auth, focus on:
1. **Input validation** — what happens with malformed AWS API requests?
2. **Resource isolation** — can one "account" access another's data?
3. **Internal network access** — can the emulator be used as SSRF proxy?
4. **Docker escape** — Lambda execution environment container breakout

## Reporting

For projects with SECURITY.md and GitHub private vulnerability reporting:

```bash
# Report via GitHub UI
https://github.com/OWNER/REPO/security/advisories/new

# Or via REST API
curl -X POST https://api.github.com/repos/OWNER/REPO/security-advisories \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -d '{
    "summary": "Title of the vulnerability",
    "description": "Detailed description with PoC steps",
    "severity": "critical|high|medium|low",
    "cve_id": null,
    "vulnerable_manifest_uri": "pom.xml"
  }'
```

## Tools

```bash
# Clone for local analysis
git clone https://github.com/OWNER/REPO.git
cd REPO

# Static analysis with Semgrep (Java security rules)
pip3 install semgrep
semgrep --config=p/java --config=p/owasp-top-ten .

# Dependency vulnerability check
mvn dependency-check:check

# OWASP Dependency Check
mvn org.owasp:dependency-check-maven:check

# Find dangerous patterns
grep -rn "Runtime.getRuntime\|ProcessBuilder\|exec(" src/ --include="*.java"
grep -rn "ObjectInputStream\|readObject\|deserialize" src/ --include="*.java"
grep -rn "velocity\|template\|render" src/ --include="*.java"
grep -rn "DocumentBuilder\|SAXParser\|XMLReader" src/ --include="*.java"
```

## Reference

This methodology was developed while auditing [Floci](https://github.com/floci-io/floci) — an open-source AWS local emulator (13.2k ⭐, Java/Quarkus, Maven).
