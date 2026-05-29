# Hermes Skills + ECC OpenCode

**249 skills** for Hermes Agent + **ECC Universal** setup for OpenCode (Linux, macOS, Windows).

---

## 🚀 Quick Install

### 1 command, all platforms:

```bash
# Linux / macOS / Git Bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-ecc-opencode/main/ecc-setup.sh)"

# Windows PowerShell
powershell -ExecutionPolicy Bypass -c "iwr -useb https://raw.githubusercontent.com/ondoz03/hermes-ecc-opencode/main/ecc-setup.ps1 | iex"
```

You'll get 3 options:
```
1) Full     — Hermes + OpenCode + ECC
2) OpenCode — OpenCode + ECC only
3) Hermes   — Restore 249 skills only
```

The script auto-checks everything — skips if already installed.

---

## 📦 What You Get

### 249 Hermes Skills

| Category | Count | Examples |
|----------|-------|----------|
| **ecc** | 33 | `deep-research`, `security-review`, `tdd-workflow`, `api-design` |
| **ecc-agents** | 63 | `planner`, `architect`, `code-reviewer`, `security-reviewer` |
| **bug-hunting** | ~45 | IDOR, XSS, SSRF, SQLi, GraphQL, LLM injection |
| **creative** | ~17 | ASCII art, diagrams, video, music, pixel art |
| **software-dev** | ~12 | TDD, debugging, code review, planning |
| **devops** | ~10 | Laravel Valet, system diagnostics, MCP |
| Others | ~69 | GitHub, research, ML, media, productivity |

### 25 OpenCode Agents

Use slash commands in your terminal:

| Command | Agent | Description |
|---------|-------|-------------|
| `/plan` | planner | Implementation planning for complex features |
| `/tdd` | tdd-guide | Test-driven development workflow |
| `/code-review` | code-reviewer | Review code quality, security, maintainability |
| `/security` | security-reviewer | Comprehensive security audit |
| `/build-fix` | build-error-resolver | Fix build and TypeScript errors |
| `/e2e` | e2e-runner | End-to-end Playwright testing |
| `/refactor-clean` | refactor-cleaner | Remove dead code and consolidate duplicates |
| `/orchestrate` | planner | Multi-agent orchestration for complex tasks |
| `/learn` | — | Extract patterns and learnings from session |
| `/checkpoint` | — | Save verification state and progress |
| `/verify` | — | Run verification loop |
| `/eval` | — | Run evaluation against criteria |
| `/update-docs` | doc-updater | Update documentation |
| `/update-codemaps` | doc-updater | Update codemaps |
| `/test-coverage` | tdd-guide | Analyze test coverage |
| `/setup-pm` | — | Configure package manager |
| `/go-review` | go-reviewer | Go code review |
| `/go-test` | tdd-guide | Go TDD workflow |
| `/go-build` | go-build-resolver | Fix Go build errors |
| `/skill-create` | — | Generate skills from git history |
| `/instinct-status` | — | View learned instincts |
| `/instinct-import` | — | Import instincts |
| `/instinct-export` | — | Export instincts |
| `/evolve` | — | Cluster instincts into skills |
| `/promote` | — | Promote project instincts to global scope |
| `/projects` | — | List known projects and instinct stats |

---

## ⚙️ Change Model

```bash
# Default model (deepseek)
ecc-init

# Or specify any model
ecc-init -m claude-sonnet-4-5
ecc-init -m gpt-4o
ecc-init -m gemini-2.0-flash
ecc-init -m deepseek-v4-flash
```

All agents inherit from one setting — no need to change each agent.

---

## 🔄 Move to New PC

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-ecc-opencode/main/ecc-setup.sh)"
```

Pick `1) Full` → wait → `opencode`. Done.

---

## 📁 Repo Contents

```
github.com/ondoz03/hermes-ecc-opencode
├── skills/          249 Hermes skills
├── local-bin/       ecc-init script
├── reference/       OpenCode config reference
├── ecc-setup.sh     Setup script (Linux/macOS/Git Bash)
├── ecc-setup.ps1    Setup script (Windows PowerShell)
└── README.md        This file
```

Source: https://github.com/affaan-m/ECC
