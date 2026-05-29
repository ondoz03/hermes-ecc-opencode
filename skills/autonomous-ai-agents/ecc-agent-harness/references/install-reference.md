# ECC Installation Reference

## Install CLI Usage

```bash
bash install.sh [options] <language> [<language> ...]

Options:
  --target <target>      Install target (default: claude)
  --profile <name>       Resolve and install a manifest profile
  --modules <ids>        Install explicit module IDs
  --with <component>     Include a user-facing install component
  --without <component>  Exclude a user-facing install component
  --skills <ids>         Install specific skill directories by ID
  --locale <code>        Install translated docs
  --config <path>        Load install intent from ecc-install.json
  --dry-run              Preview without copying files
  --json                 Machine-readable output
  --help                 Show help
```

## Install Targets

| Target | Path | Description |
|--------|------|-------------|
| claude | `~/.claude/` | Claude Code system-wide (default) |
| claude-project | `./.claude/` | Claude Code per-project |
| cursor | `./.cursor/` | Cursor editor |
| antigravity | `./.agent/` | Generic agent (closest to Hermes) |
| codex | `~/.codex/` | OpenAI Codex |
| gemini | `./.gemini/` | Google Gemini Code Assist |
| opencode | `~/.opencode/` | OpenCode |
| codebuddy | `./.codebuddy/` | CodeBuddy (Tencent) |
| joycode | `./.joycode/` | JoyCode |
| qwen | `~/.qwen/` | Qwen |
| zed | `./.zed/` | Zed editor |

## Language Tracks

ECC supports multi-language installs. Pass languages as positional args:

```bash
bash install.sh python typescript go java
```

Available languages: python, typescript, go, java, rust, cpp, ruby, php, swift, kotlin, scala, perl, r, lua, haskell, elixir, clojure, dart, csharp, react

## Locale Support

```bash
bash install.sh --target claude --locale id  # Indonesian
bash install.sh --target claude --locale ja  # Japanese
```

Available locales: en, pt-br, zh-cn, zh-tw, ja, ko, tr, ru, vi, th, de

## OpenCode Plugin Setup (via npm)

```bash
# Install globally (one-time)
npm install -g ecc-universal

# Per-project config (.opencode/opencode.json):
echo '{"plugin":["ecc-universal"]}' > .opencode/opencode.json
```

No file copying needed — the npm package bundles all agents, skills, and commands.

## Agent Conversion (Claude Code → Hermes)

Use `references/agent-conversion.py` to convert 63 agents from `agents/` to Hermes skills:

```bash
python3 /path/to/references/agent-conversion.py
```

Output goes to `~/.hermes/skills/ecc-agents/` by default.

## Quick Hermes Install (Manual)

```bash
cd ~/ECC

# Copy all ECC Hermes skills
cp -r .agents/skills/* ~/.hermes/skills/

# Or symlink specific ones
ln -s ~/ECC/.agents/skills/tdd-workflow ~/.hermes/skills/ecc-tdd-workflow
ln -s ~/ECC/.agents/skills/deep-research ~/.hermes/skills/ecc-deep-research
ln -s ~/ECC/.agents/skills/security-review ~/.hermes/skills/ecc-security-review
```

Reload in Hermes: `/reload-skills`
