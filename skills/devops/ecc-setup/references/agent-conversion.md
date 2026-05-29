# Converting Claude Code Agents to Hermes Skills

## The Problem
Claude Code agents use a different format than Hermes skills:
- Claude Code: YAML frontmatter with `name`, `description`, `tools`, `model` fields
- Hermes: SKILL.md with YAML frontmatter (`name`, `description`) + markdown body

The `tools` and `model` fields are Claude Code-specific and must be stripped.

## Conversion Script (Python)

```python
import os

agents_dir = "/path/to/agents"
output_dir = os.path.expanduser("~/.hermes/skills/target-category")
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
    
    name = None
    description = None
    clean_lines = []
    for line in frontmatter.split('\n'):
        if line.startswith('name:'):
            name = line.split(':', 1)[1].strip().strip('"\'')
            clean_lines.append(line)
        elif line.startswith('description:'):
            description = line.split(':', 1)[1].strip().strip('"\'')
            clean_lines.append(line)
        # Skip tools:, model:, and other Claude Code-specific fields
    
    skill_content = f"---\n" + "\n".join(clean_lines) + f"\n---\n\n"
    skill_content += f"# {name.replace('-', ' ').title()}\n\n"
    skill_content += f"{description or 'Converted agent'}\n\n" + body
    
    skill_dir = os.path.join(output_dir, name)
    os.makedirs(skill_dir, exist_ok=True)
    with open(os.path.join(skill_dir, "SKILL.md"), 'w') as f:
        f.write(skill_content)
```

## Key Points
- Only keep `name:` and `description:` from frontmatter
- Strip `tools:`, `model:`, and any harness-specific fields
- Add a `# Title` heading before the body
- Each agent becomes a subdirectory with SKILL.md
- Result: Hermes auto-loads based on description matching
