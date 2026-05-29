# OpenCode ECC — Namespace Debugging Journey

## Root Cause: `everything-claude-code:` Prefix

Error message:
```
Agent not found: "everything-claude-code:security-reviewer".
Available agents: build, architect, ..., security-reviewer, ...
```

Notice: `security-reviewer` IS in the available agents list, but OpenCode looks for `everything-claude-code:security-reviewer` (with namespace prefix).

## Where It Comes From

Every command template file (`commands/*.md`) has YAML frontmatter:

```yaml
# commands/security.md
---
agent: everything-claude-code:security-reviewer   ← THIS IS THE BUG
---
```

The `everything-claude-code` was the OLD name of the ECC project (before rename to ECC). These namespace references were never updated when the project renamed.

## Why `"plugin": ["ecc-universal"]` Alone Fails

OpenCode's plugin system uses `everything-claude-code` as the internal namespace. When you add `"plugin": ["ecc-universal"]` to config, OpenCode registers agents under `everything-claude-code:agent-name`. But the agents defined directly in `opencode.json` register without namespace. The command templates reference the namespaced form → agent not found.

**Solution:** Remove the plugin entirely. Define agents directly in `opencode.json`. Fix command templates to use plain agent names.

## Why `sed` Breaks Model Names

Do NOT do this:
```bash
sed -i 's/claude-sonnet-4-5/deepseek-v4-flash/g' opencode.json
```

The original model names are `anthropic/claude-sonnet-4-5`. After sed:
```
before: "model": "anthropic/claude-sonnet-4-5"
after:  "model": "anthropic/deepseek-v4-flash"   ← WRONG! leftover prefix
```

Or if the full string gets replaced incorrectly:
```
result: "deepseek-v4-flash/"  ← trailing slash from partial match
```

**Always use Python json module for JSON edits.**

## The Correct Fix (All 3 Steps)

### 1. Remove plugin
```python
d.pop('plugin', None)
```

### 2. Fix namespace in command files
```bash
sed -i 's/agent: everything-claude-code:/agent: /g' .opencode/commands/*.md
```

### 3. Remove agent-level models (inherit from parent)
```python
for agent in d.get('agent', {}).values():
    agent.pop('model', None)
# Set model once at top level
d['model'] = 'deepseek-v4-flash'
d['small_model'] = 'deepseek-v4-flash'
```

All 3 steps are automated in `ecc-init`.

## Verification

After fix, verify clean state:
```bash
grep "everything-claude-code" .opencode/commands/*.md
# Should output nothing

python3 -c "
import json
d = json.load(open('.opencode/opencode.json'))
print('plugin:', d.get('plugin', 'REMOVED'))
print('model:', d['model'])
agent_models = [(n, a.get('model')) for n, a in d.get('agent',{}).items() if 'model' in a]
print('agent-level models:', agent_models if agent_models else 'EMPTY (good)')
"
```

## Files Affected

30 command template files in `.opencode/commands/*.md`:
`security.md`, `plan.md`, `tdd.md`, `code-review.md`, `build-fix.md`, `e2e.md`, `refactor-clean.md`, `orchestrate.md`, `go-review.md`, `go-build.md`, `go-test.md`, `test-coverage.md`, `update-docs.md`, `update-codemaps.md`, `rust-review.md`, `rust-build.md`, `rust-test.md`, `checkpoint.md`, `eval.md`, `learn.md`, `verify.md`, `evolve.md`, `promote.md`, `projects.md`, `setup-pm.md`, `skill-create.md`, `instinct-status.md`, `instinct-import.md`, `instinct-export.md`, and 1 more.
