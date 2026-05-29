#!/usr/bin/env python3
"""
Convert ECC agents/ (Claude Code format) to Hermes SKILL.md format.

Usage:
    python3 agent-conversion.py [--agents-dir /path/to/ECC/agents] [--output-dir ~/.hermes/skills/ecc-agents]

This strips Claude Code-specific frontmatter (tools, model) and creates
Hermes-compatible SKILL.md files with name + description only.
"""
import os, sys, argparse

def parse_args():
    parser = argparse.ArgumentParser(description="Convert ECC agents to Hermes skills")
    parser.add_argument("--agents-dir", default="/home/who/herd/ECC/agents",
                        help="Path to ECC agents/ directory")
    parser.add_argument("--output-dir", default=os.path.expanduser("~/.hermes/skills/ecc-agents"),
                        help="Output directory for Hermes skills")
    return parser.parse_args()

def convert_agent_to_skill(agent_path: str, output_dir: str) -> bool:
    """Convert a single agent.md to SKILL.md. Returns True on success."""
    with open(agent_path, 'r') as f:
        content = f.read()

    if not content.startswith('---'):
        return False

    end = content.find('\n---', 3)
    if end == -1:
        return False

    frontmatter = content[3:end].strip()
    body = content[end+5:].strip()

    name = None
    description = None
    for line in frontmatter.split('\n'):
        if line.startswith('name:'):
            name = line.split(':', 1)[1].strip().strip('"\'')
        elif line.startswith('description:'):
            description = line.split(':', 1)[1].strip().strip('"\'')

    if not name:
        name = os.path.splitext(os.path.basename(agent_path))[0]

    clean_fm = f"name: {name}\ndescription: {description or ''}"

    skill_dir = os.path.join(output_dir, name)
    os.makedirs(skill_dir, exist_ok=True)

    skill_content = (
        f"---\n{clean_fm}\n---\n\n"
        f"# {name.replace('-', ' ').title()}\n\n"
        f"{description or 'ECC Agent'}\n\n"
        f"{body}"
    )

    with open(os.path.join(skill_dir, "SKILL.md"), 'w') as f:
        f.write(skill_content)

    return True

def main():
    args = parse_args()
    agents_dir = args.agents_dir
    output_dir = args.output_dir

    if not os.path.isdir(agents_dir):
        print(f"Error: agents directory not found: {agents_dir}")
        sys.exit(1)

    os.makedirs(output_dir, exist_ok=True)

    converted = 0
    errors = 0
    for fname in sorted(os.listdir(agents_dir)):
        if not fname.endswith('.md'):
            continue
        path = os.path.join(agents_dir, fname)
        if convert_agent_to_skill(path, output_dir):
            converted += 1
            print(f"  ✅ {fname.replace('.md', '')}")
        else:
            errors += 1
            print(f"  ❌ {fname} — no/invalid frontmatter")

    print(f"\nDone: {converted} converted, {errors} errors")
    print(f"Output: {output_dir}")

if __name__ == "__main__":
    main()
