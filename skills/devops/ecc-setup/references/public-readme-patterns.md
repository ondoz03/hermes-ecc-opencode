# Public README Patterns (from hermes-ecc-opencode)

## Structure Learned From Iteration

```
# Title + brief description

## 🚀 Quick Install (top priority)
- 1 command, all platforms
- Show Linux/macOS and Windows SEPARATELY with clear headers
- Explain what user gets (3 options, auto-check)

## 📦 What You Get
- Table of skill categories with counts + examples
- Full command table (not abbreviated) — every slash command listed

## ⚙️ Change Model
- Clearly state THIS IS FOR ECC AGENTS IN OPENCODE
- NOT for Hermes — add a callout box

## 📁 Repo Contents
- Simple file tree
- Source attribution
```

## Key Decisions

1. **Separate platform install commands** — Don't use code comments to distinguish. Use `### 🐧 Linux/macOS` and `### 🪟 Windows` headers.
2. **Full command table** — Don't abbreviate with "and 18 more". List ALL 26 commands. Users scan tables.
3. **Change Model must be unambiguous** — Add "Not for Hermes" callout so Claude Code / Cursor users don't confuse it.
4. **No "Move to New PC" section** — Redundant with Quick Install. 1 command covers both first-time and reinstall.
5. **No ANSI colors in menu** — For portable scripts, menu items must be plain text. Use `echo "  1) Full"` not `echo "  ${CYAN}1${NC}) Full"`.

## ANSI Color Usage Rules

```bash
# SAFE — echo -e with escape sequences (always renders correctly)
echo -e "${GREEN}✅ Setup complete${NC}"

# DANGEROUS — echo without -e (prints raw \033 text)
echo "  ${CYAN}1${NC}) Full"     # WRONG — shows \033[0;36m1\033[0m
echo "  1) Full"                  # RIGHT — plain text

# RULE: Only use ${COLOR} vars inside echo -e statements.
# Never in echo (no -e) or read -p prompts.
```

## Priority Order in README

1. Quick Install (solves the problem immediately)
2. What You Get (scannable tables)
3. Commands (full detail, actionable)
4. Configuration (less frequent but important)
5. Repo Contents (reference, least important)
