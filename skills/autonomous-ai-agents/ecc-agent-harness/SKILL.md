---
name: ecc-agent-harness
description: "ECC (Empirical Contextual Computation) — cross-agent harness performance optimization system. Skills, instincts, memory, security, and research-first development for Claude Code, Codex, OpenCode, Cursor, Hermes, and beyond."
version: 1.0.0
author: Hermes Agent (integrated from affaan-m/ECC)
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [ecc, cross-harness, skills, agents, optimization, multi-agent]
    homepage: https://github.com/affaan-m/ECC
    related_skills: [hermes-agent, claude-code, codex, opencode]
---

# ECC Agent Harness

ECC (Empirical Contextual Computation) is a **cross-agent harness system** by affaan-m with **198K+ GitHub stars**. It provides a unified skill/agent/rule ecosystem that works across Codex, Claude Code, Cursor, OpenCode, Gemini, Zed, GitHub Copilot, Hermes, and other AI agent harnesses.

**Current scope:** 63 agents, 249 skills, 79 legacy command shims, 1,997+ commits, 170+ contributors.

## Hermes Integration (.agents)

ECC ships Hermes-specific configurations in the `.agents/` directory:

### Skills (33 total in `.agents/skills/`)

All skills use SKILL.md format with YAML frontmatter — compatible with Hermes skill system:

| Skill | Purpose |
|-------|---------|
| `tdd-workflow` | Test-driven development with 80%+ coverage |
| `coding-standards` | Code style, linting, and conventions |
| `api-design` | REST/GraphQL API design patterns |
| `backend-patterns` | Server-side architecture patterns |
| `frontend-patterns` | Client-side architecture patterns |
| `security-review` | Code security audit workflow |
| `deep-research` | Multi-source research synthesis |
| `verification-loop` | Checkpoint-based verification |
| `eval-harness` | LLM evaluation and benchmarking |
| `agent-sort` | Agent capability classification |
| `brand-voice` | Consistent writing style enforcement |
| `content-engine` | Content generation pipeline |
| `crosspost` | Multi-platform content distribution |
| `article-writing` | Long-form article creation |
| `market-research` | Market analysis workflow |
| `investor-materials` | Pitch deck and investor docs |
| `investor-outreach` | Investor communication |
| `product-capability` | Product feature documentation |
| `mcp-server-patterns` | MCP server design patterns |
| `everything-claude-code` | Claude Code comprehensive reference |
| `exa-search` | Neural search integration |
| `fal-ai-media` | AI media generation (FAL) |
| `x-api` | X/Twitter API integration |
| `nextjs-turbopack` | Next.js + Turbopack patterns |
| `bun-runtime` | Bun JS runtime patterns |
| `e2e-testing` | End-to-end testing workflows |
| `dmux-workflows` | Multiplexed workflow orchestration |
| `documentation-lookup` | Documentation retrieval patterns |
| `agent-introspection-debugging` | Agent self-diagnosis |
| `video-editing` | Video editing workflows |
| `frontend-slides` | Presentation/slide creation |
| `strategic-compact` | Strategic planning framework |
| `mle-workflow` | Machine learning engineering |

### Plugin

A Hermes marketplace plugin manifest is available at `.agents/plugins/marketplace.json`:
- Name: `ecc`
- Version: `2.0.0-rc.1`
- Category: Productivity

## Installation

### Via ECC Install Script

```bash
# Clone the repo
git clone https://github.com/affaan-m/ECC.git ~/ECC
cd ~/ECC

# Install for Antigravity (./.agent/ target — closest to Hermes .agents format)
bash install.sh --target antigravity

# Dry-run first to preview
bash install.sh --target antigravity --dry-run
```

### Install Specific Hermes Skills

To install individual ECC skills into Hermes:

```bash
# Copy a single skill
cp -r .agents/skills/tdd-workflow ~/.hermes/skills/

# Or symlink the whole directory
ln -s ~/ECC/.agents/skills ~/.hermes/skills/ecc-skills
```

Then load them in Hermes with `/skill tdd-workflow` or `hermes -s tdd-workflow`.

### NPM Package

ECC is also available as npm packages:
- `ecc-universal` — core library
- `ecc-agentshield` — agent security scanning

```bash
npm install -g ecc-universal
```

## Install Targets

ECC supports these harness targets via the installer:

| Target | Install path | Harness |
|--------|-------------|---------|
| `claude` | `~/.claude/` | Claude Code (system-wide) |
| `claude-project` | `./.claude/` | Claude Code (per-project) |
| `cursor` | `./.cursor/` | Cursor editor |
| `antigravity` | `./.agent/` | Antigravity / generic |
| `codex` | `~/.codex/` | OpenAI Codex |
| `gemini` | `./.gemini/` | Google Gemini Code Assist |
| `opencode` | `~/.opencode/` | OpenCode |
| `codebuddy` | `./.codebuddy/` | CodeBuddy |
| `qwen` | `~/.qwen/` | Qwen |
| `zed` | `./.zed/` | Zed editor |

## ECC 2.0 Alpha

ECC v2.0.0-rc.1 includes a Rust control-plane prototype in `ecc2/` that builds locally and exposes:
- `ecc dashboard` — desktop GUI (Tkinter-based)
- `ecc start/sessions/stop/resume/status` — process management
- `ecc status --markdown --write status.md` — session state export
- `ecc work-items` — Linear/GitHub/handoff integration

## Agent Conversion (Claude Code → Hermes Skills)

ECC's `agents/` folder contains 63 agents in Claude Code format (YAML frontmatter with `tools` + `model` fields). Convert them to Hermes-compatible SKILL.md using this script:

```python
import os
agents_dir = "/path/to/ECC/agents"
output_dir = os.path.expanduser("~/.hermes/skills/ecc-agents")
os.makedirs(output_dir, exist_ok=True)
for fname in sorted(os.listdir(agents_dir)):
    if not fname.endswith('.md'): continue
    with open(os.path.join(agents_dir, fname)) as f:
        content = f.read()
    if not content.startswith('---'): continue
    end = content.find('\n---', 3)
    if end == -1: continue
    frontmatter = content[3:end].strip()
    body = content[end+5:].strip()
    name = None; description = None
    for line in frontmatter.split('\n'):
        if line.startswith('name:'): name = line.split(':',1)[1].strip().strip('"\'')
        elif line.startswith('description:'): description = line.split(':',1)[1].strip().strip('"\'')
    if not name: name = fname.replace('.md','')
    clean_fm = f"name: {name}\ndescription: {description or ''}"
    skill_dir = os.path.join(output_dir, name)
    os.makedirs(skill_dir, exist_ok=True)
    with open(os.path.join(skill_dir, "SKILL.md"), 'w') as f:
        f.write(f"---\n{clean_fm}\n---\n\n# {name.replace('-', ' ').title()}\n\n{description or 'ECC Agent'}\n\n{body}")
```

After conversion:
- `ecc/` — 33 original `.agents/skills/`
- `ecc-agents/` — 63 converted agents
- **Total: 96 ECC skills** installed in Hermes

## OpenCode Plugin Setup (Self-Contained Config) ⚠️

**IMPORTANT:** The plugin-only config `{"plugin": ["ecc-universal"]}` does NOT register agents or commands. You must use the full `opencode.json` from the package with agent definitions.

### Correct Setup

```bash
# Use the ecc-init script (recommended — auto-fixes namespace & model)
cd ~/projects/my-app
ecc-init -m deepseek-v4-flash

# Or manual: copy full .opencode from package
cd ~/projects/my-app
rm -rf .opencode
ECC_PKG=$(npm root -g)/ecc-universal
cp -r "$ECC_PKG/.opencode/"* .opencode/
# Then fix namespace + remove plugin + set model
```

### Three Critical Fixes (Auto-Handled by ecc-init)

1. **Namespace fix** — Every `commands/*.md` has `agent: everything-claude-code:X` instead of just `agent: X`. Strip it or get `Agent not found` errors.

2. **Agent-level models** — Original config defines `model` in every agent (~25 places). Set once at top-level, remove from agents. Using `sed` corrupts names like `anthropic/claude-sonnet-4-5` → `anthropic/deepseek-v4-flash`.

3. **Plugin & instructions** — Remove `plugin` entry, filter `instructions` to only reference local `.opencode/` files.

### Complete Setup

```bash
npm install -g ecc-universal   # One-time
ecc-init -m deepseek-v4-flash # Per project
opencode                     # /security, /plan, /tdd now work
```

See `ecc-setup` skill and its `references/opencode-namespace-debugging.md` for the full debugging story.

## Memory Persistence

When installing ECC for a user, save to memory with this shape:
```
ECC di /home/who/herd/ECC/ — 96 Hermes skills terinstall (33 ecc + 63 ecc-agents). Dashboard: npm run dashboard.
```

## Key Architecture

ECC is organized by harness with shared components:

```
ECC/
├── .agents/                # Hermes-specific (skills + plugin)
├── .claude/                # Claude Code configs
├── .claude-plugin/         # Claude Code plugin
├── .codex/                 # Codex configs
├── .codex-plugin/          # Codex plugin
├── .cursor/                # Cursor editor configs
├── .gemini/                # Google Gemini configs
├── .opencode/              # OpenCode configs
├── .vscode/                # VS Code settings
├── .zed/                   # Zed editor configs
├── agents/                 # Shared agent definitions
├── assets/                 # Assets (screenshots, branding)
├── commands/               # Legacy command shims
├── config/                 # Shared config files
├── contexts/               # Context definitions
├── docs/                   # Documentation
├── install.sh              # Bash entrypoint → Node installer
├── scripts/                # Node.js installer runtime
└── package.json            # npm package
```

## Updating

ECC is actively maintained (weekly releases). To update:

```bash
cd ~/ECC
git pull origin main
npm install --no-audit --no-fund
bash install.sh --target antigravity --dry-run  # preview changes
bash install.sh --target antigravity             # apply
```

## Backup Strategy

ECC + Hermes skills can be backed up to GitHub for portability across machines.

### Backup Script

The `ecc-backup.sh` script archives all skills, memories, config, and scripts:

```bash
# Install the script (already at ~/.local/bin/ecc-backup.sh)
# Run it manually:
bash ~/.local/bin/ecc-backup.sh

# Output: ~/hermes-full-backup-YYYYMMDD-HHMMSS.tar.gz (~2.9MB for ~250 skills)
```

The script captures:
- All `~/.hermes/skills/` (249+ skills)
- Memories (`~/.hermes/memories/`)
- Config (`config.yaml`, `.env`)
- Scripts (`ecc-init`, etc.)
- A registry file listing every skill with category + description

### Auto-Backup via Cron

For regular automatic backups (already configured for this user):

| Schedule | Cron | Status |
|----------|------|--------|
| Daily at 05:00 | `0 5 * * *` | ✅ Active via Hermes cron |

The daily backup script (`~/.hermes/scripts/ecc-backup-daily.sh`):
1. Syncs `~/.hermes/skills/` to Git repo
2. Syncs `~/.hermes/memories/`
3. Commits & pushes to GitHub

### GitHub Remote

Backup is split across two repos (public + private):

```bash
# Public repo (skills, scripts, reference configs)
git clone https://github.com/ondoz03/hermes-ecc-opencode.git
cp -r ~/.hermes/skills/* skills/

# Private repo (memories, config, notes — personal data)
git clone https://github.com/ondoz03/hermes-ecc-private.git
cp -r ~/.hermes/memories/* memories/
```

**Repos:**
- **Public:** `ondoz03/hermes-ecc-opencode` — skills, scripts, reference configs
- **Private:** `ondoz03/hermes-ecc-private` — memories, config, notes

### Restore on New Machine

Use the one-command setup script (auto-detects OS, shows interactive menu):

```bash
# Full setup — Hermes + OpenCode + ECC
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-ecc-opencode/main/ecc-setup.sh)"

# Or per-mode:
bash -c "$(curl -fsSL ...)" -- 1  # Full
bash -c "$(curl -fsSL ...)" -- 2  # OpenCode only
bash -c "$(curl -fsSL ...)" -- 3  # Hermes only

# Windows PowerShell:
powershell -ExecutionPolicy Bypass -c "iwr -useb https://raw.githubusercontent.com/ondoz03/hermes-ecc-opencode/main/ecc-setup.ps1 | iex"
```

For manual restore:
```bash
tar -xzf hermes-full-backup-*.tar.gz
cp -r hermes-backup-*/skills/* ~/.hermes/skills/
cp -r hermes-backup-*/memories/* ~/.hermes/memories/
cp hermes-backup-*/config/* ~/.hermes/
cp hermes-backup-*/local-bin/* ~/.local/bin/
npm install -g ecc-universal
```

### ECC Project Init Script

The `ecc-init` script (`~/.local/bin/ecc-init`) bootstraps OpenCode with full `opencode.json` from the ecc-universal package, applying all critical fixes automatically:

```bash
cd ~/projects/my-app

# Default model (deepseek)
ecc-init

# Or specify model
ecc-init -m claude-sonnet-4-5
ecc-init -m gpt-4o

# In a different directory
ecc-init -m deepseek-v4-flash /path/to/project
```

The script auto-fixes:
- ✅ Namespace prefix (`everything-claude-code:` removed from 30 command files)
- ✅ Agent-level model removal (all agents inherit from parent)
- ✅ Plugin removal (self-contained config)
- ✅ Instructions filtered (only local `.opencode/` files)

## Related

- [ECC GitHub](https://github.com/affaan-m/ECC) — main repo
- [ECC Shorthand Guide](https://github.com/affaan-m/ECC#readme) — setup and philosophy
- [ECC Security Guide](https://github.com/affaan-m/ECC/blob/main/docs/security/SECURITY_GUIDE.md) — AgentShield and attack vectors
- Hermes Backup Repo: https://github.com/ondoz03/hermes-ecc-private.git
