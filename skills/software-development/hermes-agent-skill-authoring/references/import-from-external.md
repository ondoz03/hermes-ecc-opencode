# Importing Skills from External Sources

When a user points you to an external repository (GitHub, etc.) containing a skill they want added to Hermes, follow this workflow.

## 1. Discover the Repo Content

```bash
# Check repo structure
curl -s https://api.github.com/repos/<owner>/<repo>/contents | jq -r '.[].name'

# Drill into skills/ directory if it exists
curl -s https://api.github.com/repos/<owner>/<repo>/contents/skills | jq -r '.[].name'

# Check individual skill subdirectory
curl -s https://api.github.com/repos/<owner>/<repo>/contents/skills/<skill-name> | jq -r '.[].name'
```

## 2. Read the SKILL.md

```bash
curl -s https://raw.githubusercontent.com/<owner>/<repo>/main/skills/<skill-name>/SKILL.md
```

## 3. Create the Skill in Hermes

Use `skill_manage(action='create')` with the content from the external SKILL.md.

```python
skill_manage(
    action='create',
    name='<skill-name>',
    category='<appropriate-category>',
    content='''<full-skills-md-content>'''
)
```

## 4. Pick the Right Category

Browse existing categories with `skills_list()` and pick the closest match. Don't invent new top-level categories casually.

## Common Pitfalls

1. **Not reading the full SKILL.md first.** The frontmatter `name` field may not match what you expect. Read the whole file before creating.

2. **Wrong category.** If unsure, check what categories exist via `skills_list` and match by description.

3. **External repos may use different SKILL.md formats.** The andrzej-karpathy-skills repo used standard Hermes-style SKILL.md. Other repos may have different frontmatter — adapt accordingly.

4. **Licensing.** Check the external repo's license (README or LICENSE file). MIT-licensed skills are safe to import. For other licenses, mention it to the user.

5. **Hub-installed alternatives.** If a skill exists on the Hermes skills hub, `hermes skills install <id>` is cleaner than manual import. Only use manual import for repos not on the hub.

---

## Bulk Import from Cross-Agent Frameworks (ECC Pattern)

Some external repos (e.g. ECC — Empirical Contextual Computation) bundle skills for multiple AI agent harnesses in one repo. They contain harness-specific directories like `.agents/`, `.claude/`, `.cursor/`, `.codex/` etc. These require a different approach than single-skill import.

### When to Use This Pattern

- User gives you a repo with **dozens of skills** (20+)
- The repo has **multiple harness directories** (`.agents/`, `.claude/`, `.cursor/`, etc.)
- You need to install only the **Hermes-compatible subset** (`.agents/skills/`)
- The repo provides an **install script** (install.sh) that supports multiple targets

### Step 1: Clone the Repo

```bash
cd /home/who/herd
git clone https://github.com/<owner>/<repo>.git <name>
```

Check size and structure:
```bash
du -sh <name>
find <name> -maxdepth 2 -type d | grep -v node_modules | grep -v .git | sort
```

### Step 2: Identify Hermes-Compatible Skills

Hermes looks for skills under the `.agents/skills/` directory (or similar agent-specific paths). List them:

```bash
ls <repo>/.agents/skills/
```

### Step 3: Verify Skill Format

Hermes skills require SKILL.md files with YAML frontmatter:
```yaml
---
name: skill-name
description: Use when <trigger>. <one-line behavior>.
---
```

Check a sample:
```bash
head -5 <repo>/.agents/skills/<sample>/SKILL.md
```

### Step 4: Bulk Install

Copy all skills into a Hermes category:

```bash
cd <repo>/.agents/skills
for skill in */; do
  name=$(basename "$skill")
  mkdir -p ~/.hermes/skills/<category>/"$name"
  cp -r "$skill"* ~/.hermes/skills/<category>/"$name"/
done
```

Choose a category name like `ecc`, `community`, or the framework name.

### Step 5: Verify Installation

```bash
ls ~/.hermes/skills/<category>/ | wc -l
# Should match the count from step 2
```

### Step 6: Run the Repo's Dashboard (if available)

Cross-agent frameworks often include a dashboard GUI:
```bash
cd <repo>
npm run dashboard    # Node-based
# or
python3 <dashboard_script>.py  # Python/Tkinter
```

Check `package.json` scripts section for available commands.

### Step 7: Check for Official Install Script

Many frameworks provide an install.sh that supports multiple target harnesses:
```bash
cd <repo>
bash install.sh --help   # Shows available targets
```

If a `hermes` or `agents` target exists, use it instead of manual copy.

### Pitfalls

1. **Repo size.** Large repos (ECC is 83MB, 2888 files) take time to clone. Use `--depth 1` if you only need latest.
2. **Harness confusion.** Don't install `.claude/` or `.cursor/` skills into Hermes — they may have different formats. Only install from `.agents/skills/`.
3. **Format drift.** Some cross-agent repos use their own SKILL.md format with extra frontmatter fields. Hermes only requires `name` and `description` — extra fields are harmless.
4. **Dashboard dependencies.** Python Tkinter dashboards may fail in headless environments. Node-based dashboards may need `npm install` first.
5. **Licensing.** Repos like ECC are MIT-licensed. Always check before importing.

---

## Converting Claude Code Agents to Hermes Skills

Some cross-agent frameworks (ECC, etc.) bundle a separate `agents/` directory containing **Claude Code agent files** — `.md` files with YAML frontmatter including `tools` and `model` fields. These are NOT Hermes-compatible as-is, but can be bulk-converted.

### When to Use This Pattern

- A repo has an `agents/` directory with `.md` files in Claude Code agent format
- You've already installed the `.agents/skills/` skills (the easy part)
- The user also wants the **63 agents** converted into Hermes skills
- The agent format looks like:
  ```yaml
  ---
  name: security-reviewer
  description: Security vulnerability detection...
  tools: ["Read", "Grep", "Glob"]
  model: opus
  ---
  ## Prompt Defense Baseline
  ...
  ```

### Conversion Script

```python
import os

agents_dir = "/path/to/repo/agents"
output_dir = os.path.expanduser("~/.hermes/skills/<category>")
os.makedirs(output_dir, exist_ok=True)

for fname in sorted(os.listdir(agents_dir)):
    if not fname.endswith('.md'):
        continue

    path = os.path.join(agents_dir, fname)
    with open(path, 'r') as f:
        content = f.read()

    # Parse YAML frontmatter
    if not content.startswith('---'):
        continue
    end = content.find('\n---', 3)
    if end == -1:
        continue

    frontmatter = content[3:end].strip()
    body = content[end+5:].strip()

    # Extract name and description
    name = None
    description = None
    for line in frontmatter.split('\n'):
        if line.startswith('name:'):
            name = line.split(':', 1)[1].strip().strip('"\'')
        elif line.startswith('description:'):
            description = line.split(':', 1)[1].strip().strip('"\'')

    if not name:
        name = fname.replace('.md', '')

    # Filter out Claude Code-specific frontmatter (tools, model)
    hero_lines = []
    for line in frontmatter.split('\n'):
        if line.startswith('tools:') or line.startswith('model:'):
            continue
        hero_lines.append(line)

    # Build SKILL.md
    skill_content = f"---\n{chr(10).join(hero_lines)}\n---\n\n"
    skill_content += f"# {name.replace('-', ' ').title()}\n\n"
    skill_content += f"{description or 'ECC Agent'}\n\n"
    skill_content += body

    skill_dir = os.path.join(output_dir, name)
    os.makedirs(skill_dir, exist_ok=True)
    with open(os.path.join(skill_dir, "SKILL.md"), 'w') as f:
        f.write(skill_content)
```

### What the Conversion Does

1. **Reads** each `.md` file from the `agents/` directory
2. **Extracts** the YAML frontmatter (name, description)
3. **Strips** Claude Code-specific fields (`tools:`, `model:`) — Hermes doesn't need these
4. **Wraps** the body in a proper SKILL.md with a title header
5. **Installs** into `~/.hermes/skills/<category>/<agent-name>/SKILL.md`

### Verify the Output

```bash
ls ~/.hermes/skills/<category>/ | wc -l
head -10 ~/.hermes/skills/<category>/planner/SKILL.md
# Expected:
# ---
# name: planner
# description: ...
# ---
```

### Naming Convention

- Install in a **separate sub-category** from the `.agents/skills/` skills (e.g. `ecc-agents` vs `ecc`) so they don't mix
- This gives the user a clear mental model: `ecc/` = native Hermes skills, `ecc-agents/` = converted Claude Code agents

### Pitfalls

1. **Prompt Defense Baselines.** Claude Code agents often include "Prompt Defense Baseline" sections at the top — these are harmless for Hermes but add token overhead. Optionally strip them with a regex if the user prefers lean skills.
2. **Missing `name`.** Some agent files use filename-based naming (like `gan-evaluator.md`) but lack a `name:` field in frontmatter. Fall back to the stem of the filename.
3. **No `description`.** Some agents lack a description field. Auto-generate one from the filename or first paragraph.
4. **Double installation.** Don't install agents that duplicate already-installed `.agents/skills/` entries. Check for name collisions: `comm -12 <(ls agents/ | sed 's/.md$//' | sort) <(ls .agents/skills/ | sort)`
