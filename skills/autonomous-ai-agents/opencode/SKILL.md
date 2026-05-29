---
name: opencode
description: "Delegate coding to OpenCode CLI (features, PR review)."
version: 1.2.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [Coding-Agent, OpenCode, Autonomous, Refactoring, Code-Review]
    related_skills: [claude-code, codex, hermes-agent, ecc-setup]
---

# OpenCode CLI

Use [OpenCode](https://opencode.ai) as an autonomous coding worker orchestrated by Hermes terminal/process tools. OpenCode is a provider-agnostic, open-source AI coding agent with a TUI and CLI.

## When to Use

- User explicitly asks to use OpenCode
- You want an external coding agent to implement/refactor/review code
- You need long-running coding sessions with progress checks
- You want parallel task execution in isolated workdirs/worktrees

## Prerequisites

- OpenCode installed (see platform-specific methods below)
- Auth configured: `opencode auth login` or set provider env vars (OPENROUTER_API_KEY, etc.)
- Verify: `opencode auth list` should show at least one provider
- Git repository for code tasks (recommended)
- `pty=true` for interactive TUI sessions

### Install OpenCode (Cross-Platform)

| Platform | Method | Command |
|----------|--------|---------|
| Linux (curl) | Install script | `curl -fsSL https://opencode.ai/install \| bash` |
| macOS (brew) | Homebrew | `brew install opencode` |
| Windows (npm) | Node.js | `npm i -g opencode-ai` |
| macOS/Linux (npm) | Node.js | `npm i -g opencode-ai` |

**Note on npm global installs:** If you use Hermes Agent, `~/.local/bin/npm` may symlink to Hermes' Node (`~/.hermes/node/bin/npm`). This is fine for OpenCode itself — the CLI binary installs correctly regardless. But for ECC plugin integration, see the ECC Setup skill (`ecc-setup`) for the self-contained config approach that avoids npm dependency entirely.

## ECC Agent Integration (Via ecc-setup Skill)

For adding ECC agents (25+ specialized agents like `security-reviewer`, `planner`, `code-reviewer`) to OpenCode, load the `ecc-setup` skill. It covers:

- Self-contained `.opencode/opencode.json` config (no plugin dependency)
- Agent definitions + 27 slash commands (`/security`, `/plan`, `/tdd`, etc.)
- Cross-platform `ecc-init` script with interactive 3-mode menu
- Model selection via `ecc-init -m <model>`
- Fixes for namespace `everything-claude-code:` in command templates
- Agent-level model inheritance from parent config

### ⚠️ CRITICAL: Command Templates Have Old Namespace

Every `commands/*.md` file from ECC's npm package has YAML frontmatter referencing agents with the **old** namespace prefix:

```yaml
# WRONG — causes "Agent not found" error
agent: everything-claude-code:security-reviewer
```

The fix is to strip the prefix from ALL 30 command files:
```bash
sed -i 's/agent: everything-claude-code:/agent: /g' .opencode/commands/*.md
```

This is automated in `ecc-init`. If you manually copy configs, don't skip this step.

### ⚠️ CRITICAL: Agent-Level Models Break on Provider Switch

Original ECC config defines `model` inside each agent object (~25 places). When switching providers, you must update all of them. Using `sed` for this corrupts names (e.g., `anthropic/claude-sonnet-4-5` → `anthropic/deepseek-v4-flash`).

**Fix:** Remove `model` from all agent objects, set once at top level:
```python
for agent in d.get('agent', {}).values():
    agent.pop('model', None)
d['model'] = 'my-model'
```

### ⚠️ Plugin Config Alone Doesn't Work

Config `{"plugin": ["ecc-universal"]}` does NOT register agents or commands. You need the full `opencode.json` with agent definitions. See `ecc-setup` skill for details.

### Quick Setup
```bash
rm -rf .opencode           # If previously misconfigured
ecc-init -m deepseek-v4-flash
opencode
# Now /security, /plan, /tdd etc. are available
```

For detailed debugging reference, see `ecc-setup` skill's `references/opencode-namespace-debugging.md`.

## Binary Resolution (Important)

Shell environments may resolve different OpenCode binaries. If behavior differs between your terminal and Hermes, check:

```
terminal(command="which -a opencode")
terminal(command="opencode --version")
```

If needed, pin an explicit binary path:

```
terminal(command="$HOME/.opencode/bin/opencode run '...'", workdir="~/project", pty=true)
```

## One-Shot Tasks

Use `opencode run` for bounded, non-interactive tasks:

```
terminal(command="opencode run 'Add retry logic to API calls and update tests'", workdir="~/project")
```

Attach context files with `-f`:

```
terminal(command="opencode run 'Review this config for security issues' -f config.yaml -f .env.example", workdir="~/project")
```

Show model thinking with `--thinking`:

```
terminal(command="opencode run 'Debug why tests fail in CI' --thinking", workdir="~/project")
```

Force a specific model:

```
terminal(command="opencode run 'Refactor auth module' --model openrouter/anthropic/claude-sonnet-4", workdir="~/project")
```

## Interactive Sessions (Background)

For iterative work requiring multiple exchanges, start the TUI in background:

```
terminal(command="opencode", workdir="~/project", background=true, pty=true)
# Returns session_id

# Send a prompt
process(action="submit", session_id="<id>", data="Implement OAuth refresh flow and add tests")

# Monitor progress
process(action="poll", session_id="<id>")
process(action="log", session_id="<id>")

# Send follow-up input
process(action="submit", session_id="<id>", data="Now add error handling for token expiry")

# Exit cleanly — Ctrl+C
process(action="write", session_id="<id>", data="\x03")
# Or just kill the process
process(action="kill", session_id="<id>")
```

**Important:** Do NOT use `/exit` — it is not a valid OpenCode command and will open an agent selector dialog instead. Use Ctrl+C (`\x03`) or `process(action="kill")` to exit.

### TUI Keybindings

| Key | Action |
|-----|--------|
| `Enter` | Submit message (press twice if needed) |
| `Tab` | Switch between agents (build/plan) |
| `Ctrl+P` | Open command palette |
| `Ctrl+X L` | Switch session |
| `Ctrl+X M` | Switch model |
| `Ctrl+X N` | New session |
| `Ctrl+X E` | Open editor |
| `Ctrl+C` | Exit OpenCode |

### Resuming Sessions

After exiting, OpenCode prints a session ID. Resume with:

```
terminal(command="opencode -c", workdir="~/project", background=true, pty=true)  # Continue last session
terminal(command="opencode -s ses_abc123", workdir="~/project", background=true, pty=true)  # Specific session
```

## Common Flags

| Flag | Use |
|------|-----|
| `run 'prompt'` | One-shot execution and exit |
| `--continue` / `-c` | Continue the last OpenCode session |
| `--session <id>` / `-s` | Continue a specific session |
| `--agent <name>` | Choose OpenCode agent (build or plan) |
| `--model provider/model` | Force specific model |
| `--format json` | Machine-readable output/events |
| `--file <path>` / `-f` | Attach file(s) to the message |
| `--thinking` | Show model thinking blocks |
| `--variant <level>` | Reasoning effort (high, max, minimal) |
| `--title <name>` | Name the session |
| `--attach <url>` | Connect to a running opencode server |

## Procedure

1. Verify tool readiness:
   - `terminal(command="opencode --version")`
   - `terminal(command="opencode auth list")`
2. For bounded tasks, use `opencode run '...'` (no pty needed).
3. For iterative tasks, start `opencode` with `background=true, pty=true`.
4. Monitor long tasks with `process(action="poll"|"log")`.
5. If OpenCode asks for input, respond via `process(action="submit", ...)`.
6. Exit with `process(action="write", data="\x03")` or `process(action="kill")`.
7. Summarize file changes, test results, and next steps back to user.

## PR Review Workflow

OpenCode has a built-in PR command:

```
terminal(command="opencode pr 42", workdir="~/project", pty=true)
```

Or review in a temporary clone for isolation:

```
terminal(command="REVIEW=$(mktemp -d) && git clone https://github.com/user/repo.git $REVIEW && cd $REVIEW && opencode run 'Review this PR vs main. Report bugs, security risks, test gaps, and style issues.' -f $(git diff origin/main --name-only | head -20 | tr '\n' ' ')", pty=true)
```

## Parallel Work Pattern

Use separate workdirs/worktrees to avoid collisions:

```
terminal(command="opencode run 'Fix issue #101 and commit'", workdir="/tmp/issue-101", background=true, pty=true)
terminal(command="opencode run 'Add parser regression tests and commit'", workdir="/tmp/issue-102", background=true, pty=true)
process(action="list")
```

## Session & Cost Management

List past sessions:

```
terminal(command="opencode session list")
```

Check token usage and costs:

```
terminal(command="opencode stats")
terminal(command="opencode stats --days 7 --models anthropic/claude-sonnet-4")
```

## Pitfalls

- Interactive `opencode` (TUI) sessions require `pty=true`. The `opencode run` command does NOT need pty.
- `/exit` is NOT a valid command — it opens an agent selector. Use Ctrl+C to exit the TUI.
- PATH mismatch can select the wrong OpenCode binary/model config.
- If OpenCode appears stuck, inspect logs before killing:
  - `process(action="log", session_id="<id>")`
- Avoid sharing one working directory across parallel OpenCode sessions.
- Enter may need to be pressed twice to submit in the TUI (once to finalize text, once to send).

## Orchestration Integration (Octogent, etc.)

OpenCode can run inside orchestration layers like **Octogent** (hesamsheikh/octogent) — a multi-agent dashboard that manages terminals, tentacles (scoped context folders), and child-agent spawning.

### Octogent's Provider Architecture

Octogent supports multiple agent backends via a `TerminalAgentProvider` type:

- `"claude-code"` (default) — runs `claude` binary
- `"codex"` — runs `codex` binary

Each provider maps to a bootstrap command in `TERMINAL_BOOTSTRAP_COMMANDS`. When a terminal session starts, Octogent runs that command inside a node-pty. The startup preflight checks for both `claude` and `codex` binaries — having either one is sufficient.

### Three Approaches to Use OpenCode Instead of Claude Code

**A. Quick symlink (1 minute, hack):**

```bash
ln -sf $(which opencode) ~/.local/bin/claude
```

Octogent calls `claude` but gets OpenCode. Only works if you never use real Claude Code alongside.

**B. Reuse `codex` provider (clean, no fork):**

```bash
ln -sf $(which opencode) ~/.local/bin/codex
```

Then create terminals with `agentProvider: "codex"` (or via CLI `--agent-provider codex`). This avoids clobbering the `claude` binary, so both can coexist. Octogent already accepts `"codex"` as a valid provider.

**C. Fork & add an `"opencode"` provider (proper, 4 files):**

Files to modify:
1. **`packages/core/src/domain/agentRuntime.ts`** — add `"opencode"` to `TerminalAgentProvider` union type and `TERMINAL_AGENT_PROVIDERS` array
2. **`apps/api/src/terminalRuntime/constants.ts`** — add `opencode: "opencode"` to `TERMINAL_BOOTSTRAP_COMMANDS`
3. **`apps/api/src/startupPrerequisites.ts`** — add `opencode` to the `StartupPrerequisiteAvailability` type and the health check
4. **`apps/api/src/createApiServer/terminalParsers.ts`** — update the error message in `parseTerminalAgentProvider` to include `"opencode"`

### Bug Bounty with Octogent + OpenCode

Octogent's tentacle system maps naturally to bug bounty targets:

```
.octogent/tentacles/
├── gitlab-bb/          → CONTEXT.md (scope, endpoints), todo.md (recon checklist)
├── shopify-bb/         → CONTEXT.md, todo.md
└── general-recon/      → CONTEXT.md, todo.md
```

Each tentacle gets:
- **`CONTEXT.md`** — target description, scope, auth tokens, endpoints
- **`todo.md`** — task list with checkboxes that Octogent uses to generate worker prompts
- Skills/methodology files (the bug-hunting skills) referenced in context

The Octogent UI shows all terminal sessions, so you can run parallel workers:
- One terminal doing subdomain recon
- One terminal doing JS analysis
- One terminal doing manual SSRF testing

See `bug-bounty` skill's `references/octogent-bug-hunting.md` for detailed setup.

### Parallel Bug Bounty Work Pattern

```bash
# Start Octogent dashboard
cd ~/targets/example-program && octogent

# Create bug-hunting tentacles
octogent tentacle create recon --description "Subdomain + URL recon"
octogent tentacle create js-audit --description "JS secret extraction"
octogent tentacle create manual-test --description "Manual auth + IDOR"

# Create terminals with OpenCode backend
octogent terminal create --tentacle-id recon \
  --initial-prompt "Run subfinder, httpx, katana on target.com. Save results." \
  --agent-provider codex

octogent terminal create --tentacle-id js-audit \
  --initial-prompt "Download all JS from target.com, run SecretFinder, report secrets." \
  --agent-provider codex
```

**Prerequisites for this workflow:**
- OpenCode symlinked to `codex` (approach B)
- Bootstrap prompt for each tentacle (auto-loaded from tentacle's `todo.md`)
- API running on localhost:8787

## Verification

Smoke test:

```
terminal(command="opencode run 'Respond with exactly: OPENCODE_SMOKE_OK'")
```

Success criteria:
- Output includes `OPENCODE_SMOKE_OK`
- Command exits without provider/model errors
- For code tasks: expected files changed and tests pass

## Rules

1. Prefer `opencode run` for one-shot automation — it's simpler and doesn't need pty.
2. Use interactive background mode only when iteration is needed.
3. Always scope OpenCode sessions to a single repo/workdir.
4. For long tasks, provide progress updates from `process` logs.
5. Report concrete outcomes (files changed, tests, remaining risks).
6. Exit interactive sessions with Ctrl+C or kill, never `/exit`.
