#!/usr/bin/env python3
"""Add Laravel SKILL.md files as OpenCode instructions."""
import json, os, glob, shutil

opencode_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".opencode"))
config_path = os.path.join(opencode_dir, "opencode.json")

if not os.path.exists(config_path):
    # Not in a project with .opencode, try current dir
    config_path = ".opencode/opencode.json"
    if not os.path.exists(config_path):
        exit(0)
    opencode_dir = ".opencode"

with open(config_path) as f:
    d = json.load(f)

instr = d.get("instructions", [])
base = opencode_dir
inst_dir = os.path.join(base, "instructions")
os.makedirs(inst_dir, exist_ok=True)

for sk_path in sorted(glob.glob(os.path.expanduser("~/.hermes/skills/ecc-full/laravel-*/SKILL.md"))):
    name = os.path.basename(os.path.dirname(sk_path))
    dest = os.path.join(inst_dir, name + ".md")
    if not os.path.exists(dest):
        shutil.copy2(sk_path, dest)
    rel = os.path.relpath(dest, base)
    if rel not in instr:
        instr.append(rel)

d["instructions"] = instr
with open(config_path, "w") as f:
    json.dump(d, f, indent=2)

count = len([s for s in glob.glob(os.path.expanduser("~/.hermes/skills/ecc-full/laravel-*/SKILL.md")) if os.path.exists(os.path.join(inst_dir, os.path.basename(os.path.dirname(s)) + ".md"))])
print(f"✅ Added {count} Laravel skill instructions")
