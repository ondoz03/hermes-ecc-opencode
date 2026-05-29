# Agent Conversion: Claude Code → Hermes SKILL.md

Convert 63 Claude Code agents from ECC's `agents/` folder to Hermes-compatible SKILL.md format.

## Source Format (Claude Code)

```yaml
---
name: planner
description: Expert planning specialist for complex features...
tools: ["Read", "Grep", "Glob"]
model: opus
---
## Prompt Defense Baseline
...
## Your Role
...
```

## Target Format (Hermes)

```yaml
---
name: planner
description: Expert planning specialist for complex features...
---
# Planner
...
```

## Conversion Rules

1. Keep `name:` and `description:` from YAML frontmatter
2. Remove `tools:`, `model:`, and other Claude-specific fields
3. Add `# Title` heading (title-case version of name)
4. Keep body markdown content unchanged

## Python Conversion Script

```python
import os

agents_dir = "/path/to/ECC/agents"
output_dir = "~/.hermes/skills/ecc-agents"
os.makedirs(output_dir, exist_ok=True)

for fname in sorted(os.listdir(agents_dir)):
    if not fname.endswith('.md'):
        continue
    
    path = os.path.join(agents_dir, fname)
    with open(path, 'r') as f:
        content = f.read()
    
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
    
    # Build clean SKILL.md (filter out Claude-specific fields)
    clean_fm_lines = []
    for line in frontmatter.split('\n'):
        if line.startswith('tools:') or line.startswith('model:'):
            continue
        clean_fm_lines.append(line)
    
    skill_content = "---\n" + "\n".join(clean_fm_lines) + "\n---\n\n"
    skill_content += f"# {name.replace('-', ' ').title()}\n\n"
    skill_content += (description or 'ECC Agent') + "\n\n"
    skill_content += body
    
    skill_dir = os.path.join(output_dir, name)
    os.makedirs(skill_dir, exist_ok=True)
    with open(os.path.join(skill_dir, "SKILL.md"), 'w') as f:
        f.write(skill_content)
    
    print(f"✅ {name}")
```

## Stats

| Item | Count |
|------|-------|
| Agents in `agents/` | 63 |
| Successfully converted | 63 |
| Failed | 0 |
| Output dir | `~/.hermes/skills/ecc-agents/` |
| Total Hermes ECC skills | 96 (33 ecc + 63 ecc-agents) |
