---
name: ecc-setup
description: Complete ECC (Empirical Contextual Computation) setup for Hermes + OpenCode — cross-platform (Linux/macOS/Windows). Skills, OpenCode config with namespace fixes, interactive 3-mode setup, daily backup. Load when user asks about ECC, affaan-m, agent skills, OpenCode setup, or cross-harness agent systems.
---

# ECC Setup — Complete Reference

ECC (Empirical Contextual Computation) by @affaan-m — cross-harness AI agent operating system.

## Two Repos

**Public:** `ondoz03/hermes-ecc-opencode` — skills, scripts, reference configs  
**Private:** `ondoz03/hermes-ecc-private` — personal memories, config, notes

## Architecture

```
Hermes (saya):  ~/.hermes/skills/ecc/ + /ecc-agents/  → 96 skills, auto-load
OpenCode CLI:   .opencode/opencode.json + commands/*.md  → 25-63 agents via /command
```

Same source (ECC), different format & usage pattern.

## OpenCode Setup — The 3 Critical Fixes

### 🔥 Fix 1: Namespace in Command Templates
**Problem:** Every `commands/*.md` has `agent: everything-claude-code:security-reviewer` (old project name). Causes `Agent not found` error even though agent exists in available list.
**Solution:** `sed -i 's/agent: everything-claude-code:/agent: /g' .opencode/commands/*.md`
**Reference:** `references/opencode-namespace-debugging.md` for full debugging journey.

### 🔥 Fix 2: Plugin Config Alone Is Not Enough
**Problem:** `{"plugin": ["ecc-universal"]}` does NOT register agents or commands.
**Solution:** Use full `opencode.json` from package. Remove `plugin` entry entirely since agents are defined directly.

### 🔥 Fix 3: Agent-Level Models
**Problem:** Original config has `model` in every agent (~25 places). Switching provider requires touching all. Using `sed` corrupts names (e.g., `anthropic/claude-sonnet-4-5` → `anthropic/deepseek-v4-flash`).
**Solution:** Remove `model` from all agents, set once at top level. Use Python json, NOT sed.

## Cross-Platform One-Command Setup

3 interactive modes — auto-checks, skips if already installed:

```
1) Full     — Hermes + OpenCode + ECC
2) OpenCode — OpenCode + ECC only
3) Hermes   — Restore 249 skills only
```

### ⚠️ Menu Color Pitfall

Do **NOT** use ANSI color codes (`${CYAN}`, `${NC}`) in `echo` (without `-e`) statements. They print as raw `\033[0;36m` text on terminals that auto-escape or pipe through non-TTY streams.

```bash
# WRONG — shows raw ANSI codes
echo "  ${CYAN}1${NC}) Full"

# RIGHT — plain text
echo "  1) Full"
```

Use `${CYAN}`/`${NC}` only with `echo -e` (colored output messages). Menu prompts should always be plain text for portability.

### One-Liner (All Platforms)

```bash
# Linux / macOS / Git Bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-ecc-opencode/main/ecc-setup.sh)"

# Windows PowerShell
powershell -ExecutionPolicy Bypass -c "iwr -useb https://raw.githubusercontent.com/ondoz03/hermes-ecc-opencode/main/ecc-setup.ps1 | iex"
```

### Script Flow (in Order)
1. Check prerequisites (node, npm, git)
2. **Check & install OpenCode** (tries brew, curl script, then npm fallback)
3. Clone backup repo (pull if exists)
4. Install `ecc-universal` (skip if exists)
5. Setup `ecc-init` to `~/.local/bin/`
6. **Check Hermes installed** — warn if `~/.hermes/config.yaml` missing; still downloads skills for later
7. Restore 249 skills + memories + config (skip if already present)
9. Init OpenCode project — Python-based json patching (NOT sed, avoids model-name corruption)

## Change Model

```bash
ecc-init -m claude-sonnet-4-5  # Specify any model
ecc-init -m gpt-4o
ecc-init -m deepseek-v4-flash  # Default
```

Script auto-fixes: model inheritance, namespace, plugin removal, instruction filtering.

## Hermes Node vs System Node

`npm` in PATH symlinks to Hermes' Node (`~/.hermes/node/bin/npm`). All `npm install -g` goes to Hermes. For OpenCode, ecc-init is self-contained — no global npm needed.

To use system NVM Node:
```bash
~/.nvm/versions/node/v24.16.0/bin/npm install -g <package>
```

## Daily Backup (Cron)

**Schedule:** Every day at 05:00 — job "ECC Daily Backup"
**Script:** `~/.local/bin/ecc-backup-daily.sh`
**Destination:** Private repo (`ondoz03/hermes-ecc-private`) — memories, config, notes

## Verification After Setup

```bash
# Check namespace is clean
grep "everything-claude-code" .opencode/commands/*.md  # Should be empty

# Check agent availability
python3 -c "
import json
d = json.load(open('.opencode/opencode.json'))
print('Model:', d['model'])
print('Plugin:', d.get('plugin', 'REMOVED'))
agent_models = [(n, a.get('model')) for n, a in d.get('agent',{}).items() if 'model' in a]
print('Agent-level models:', agent_models if agent_models else 'EMPTY (good)')
"

# Test OpenCode
opencode run 'Respond with OK if config loads'
```

## ECC Dashboard
```bash
cd /home/who/herd/ECC && npm run dashboard
```

## Troubleshooting Reference

**Error: Agent not found** → Namespace bug. `rm -rf .opencode && ecc-init -m <model>`
**Error: Model X not valid** → Wrong model name. `ecc-init -m <correct-model>`
**Error: Command not found** → Plugin-only config. `rm -rf .opencode && ecc-init`

See `references/opencode-namespace-debugging.md` for full root cause analysis.
