# OpenCode Namespace Fix — "everything-claude-code:" Agent Not Found

## Error Pattern
```
Agent not found: "everything-claude-code:security-reviewer"
Available agents: build, architect, ..., security-reviewer, ...
```

## Root Cause
File `commands/*.md` memiliki YAML frontmatter dengan namespace lama:
```yaml
---
agent: everything-claude-code:security-reviewer
---
```

Agent terdaftar sebagai `security-reviewer` (tanpa namespace), tapi command merujuk `everything-claude-code:security-reviewer`.

## Affected Files
30 file di `commands/` masing-masing punya frontmatter dengan namespace. Contoh:
- `security.md` → `agent: everything-claude-code:security-reviewer`
- `plan.md` → `agent: everything-claude-code:planner`
- `tdd.md` → `agent: everything-claude-code:tdd-guide`
- `code-review.md` → `agent: everything-claude-code:code-reviewer`
- `build-fix.md` → `agent: everything-claude-code:build-error-resolver`
- `orchestrate.md` → `agent: everything-claude-code:planner`
- Dan 24 file lainnya

## Fix Command
```bash
sed -i 's/agent: everything-claude-code:/agent: /g' .opencode/commands/*.md
```

## Verify
```bash
grep "^agent:" .opencode/commands/*.md | grep "everything-claude-code"
# Output kosong = OK
```

## Why This Happens
Package `ecc-universal` (sebelumnya bernama `everything-claude-code`) belum update frontmatter command files. Namespace `everything-claude-code:` adalah sisa dari nama repository lama.

## Prevention in ecc-init
Script `ecc-init` otomatis menjalankan fix ini. Tapi jika user masih error, mereka perlu reset `.opencode/`:
```bash
rm -rf .opencode && ecc-init -m <model>
```
