# Octogent for Bug Hunting

[Octogent](https://github.com/hesamsheikh/octogent) is a multi-agent orchestration dashboard that manages scoped "tentacles" (context folders) and parallel terminal sessions. It can be used as a force multiplier for bug bounty hunting.

## Architecture Overview

```
Octogent Dashboard (UI at localhost:8787)
  ├── Tentacle: recon        → .octogent/tentacles/recon/{CONTEXT.md, todo.md}
  ├── Tentacle: js-audit     → .octogent/tentacles/js-audit/
  ├── Tentacle: manual-test  → .octogent/tentacles/manual-test/
  └── Terminal sessions (PTY) — each runs an agent CLI
       ├── claude   (default, requires Claude Code)
       ├── codex    (requires Codex CLI)
       └── opencode (via symlink — see below)
```

Each tentacle is a scoped job container with:
- `CONTEXT.md` — target description, scope, auth tokens, methodology checklist
- `todo.md` — task items with `[ ]` / `[x]` checkboxes
- Extra markdown files (handoff notes, results)

## Dual-Provider System

Octogent natively supports two agent backends:
- `"claude-code"` → runs `claude` binary in the PTY
- `"codex"` → runs `codex` binary in the PTY

Default is `"claude-code"`. Set via `agentProvider` field when creating a terminal.

**To use OpenCode instead of Claude Code**, the simplest approach is:

```bash
# Symlink opencode as codex (both can coexist with real claude)
ln -sf $(which opencode) ~/.local/bin/codex

# Then create terminals with --agent-provider codex
octogent terminal create --tentacle-id recon \
  --initial-prompt "Run subfinder on target.com" \
  --agent-provider codex
```

See `opencode` skill's "Orchestration Integration" section for all 3 approaches (symlink, codex-provider, fork).

## Bug Bounty Tentacle Setup

### Step 1: Initialize Octogent

```bash
cd ~/targets/PROGRAM_NAME
octogent init
```

### Step 2: Create Tentacles by Phase

```bash
# Phase 1: Recon
octogent tentacle create recon --description "Subdomain enum, URL crawl, tech detect"

# Phase 2: Mapping
octogent tentacle create mapping --description "JS secrets, API endpoints, auth model"

# Phase 3: Vulnerability hunting per class
octogent tentacle create idor --description "IDOR test on API endpoints"
octogent tentacle create auth --description "Auth bypass, OAuth, password reset"
octogent tentacle create xss --description "Reflected/DOM/Stored XSS sinks"
```

### Step 3: Write CONTEXT.md for Each Tentacle

```markdown
# CONTEXT.md — recon

## Target
- Domain: target.com
- Wildcard: *.target.com
- Bug bounty program: HackerOne/target

## Scope Notes
- Limit to unauthenticated endpoints first
- Avoid: *.admin.target.com (out of scope)
- Rate limit: 10 req/s

## Tools Available
- subfinder, httpx, dnsx, katana, ffuf, nuclei
- interactsh-client for OOB

## Auth
- No auth needed for Phase 1
- Test accounts: user1@test.com / user2@test.com
```

### Step 4: Write todo.md as Execution Surface

```markdown
# todo.md — recon

## Immediate
- [ ] subfinder -d target.com | tee subs.txt
- [ ] httpx -l subs.txt -status-code -title -tech-detect
- [ ] katana -d 3 -silent | tee urls.txt

## If-Time
- [ ] gau target.com | anew urls.txt
- [ ] nuclei -l live.txt -severity critical,high,medium
- [ ] ffuf for API endpoints
```

### Step 5: Launch Parallel Workers

```bash
# Terminal 1: recon (via OpenCode as codex)
octogent terminal create --tentacle-id recon \
  --initial-prompt "Run the recon pipeline for target.com" \
  --agent-provider codex

# Terminal 2: JS analysis (via OpenCode)  
octogent terminal create --tentacle-id mapping \
  --initial-prompt "Download all JS files, extract endpoints and secrets" \
  --agent-provider codex

# Terminal 3: manual IDOR testing (via OpenCode)
octogent terminal create --tentacle-id idor \
  --initial-prompt "Test IDOR on /api/v2/users/{id}" \
  --agent-provider codex

# Monitor all 3 in Octogent's web UI
open http://localhost:8787
```

## Multi-Agent Bug Hunting Strategy

### Tentacle-to-Phase Mapping

| Hunting Phase | Recommended Tentacles | Agent Focus |
|---------------|----------------------|-------------|
| Recon | `recon`, `js-audit`, `tech-stack` | Automated toolchain (+ `opencode run`) |
| Mapping | `api-mapping`, `auth-model` | Crawl + introspection |
| Hunt (per class) | `idor`, `ssrf`, `xss`, `auth`, `graphql` | Deep manual testing |
| Validate | `chain`, `impact` | A→B signal method, escalation |
| Report | `report` | PoC writing, export |

### Spawn Pattern

Octogent can spawn **child agents** from todo items. A done item in a parent tentacle triggers a new child terminal:

```
Tentacle: recon
├── todo: [x] subdomain enum done
├── todo: [ ] JS analysis → spawns child tentacle js-audit
└── todo: [ ] Manual IDOR → spawns child tentacle idor
```

This maps perfectly to the bb-methodology "A→B Signal Method" — when a recon finding surfaces a candidate, spawn a focused child tentacle for that specific class.

### Inter-Agent Messaging

Workers can message each other via Octogent's channel system:

```bash
# From inside a recon worker, notify the IDOR worker
octogent channel send <idor-terminal-id> \
  "Found API endpoint /api/v2/users/{id} — test for IDOR"
```

## Caveats & Pitfalls

- **Memory usage**: 32 concurrent PTY sessions max by default. Bug hunting rarely needs >5.
- **API restart kills sessions**: PTY sessions don't survive Octogent API restart. Save work to tentacle files first.
- **OpenCode vs Claude nuances**: OpenCode's `run` mode (non-interactive) works differently from Claude Code's. If using OpenCode inside Octogent's PTY bootstrap, the agent will be in interactive TUI mode.
- **Rate limits accelerate**: Multiple parallel workers hitting the same target increase WAF/rate-limit triggers. Stagger your launch or use different proxy exits.
- **Not a replacement for manual testing**: Octogent orchestrates agents, not your brain. The methodology (bb-methodology, bug-bounty skill checklists) still drives what each worker does.
