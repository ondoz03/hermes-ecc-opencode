# Bug Hunting Vault — Obsidian Documentation Workflow

Systematic documentation of bug bounty progress using an interconnected Obsidian vault. Keeps targets, techniques, findings, and progress organized with graph-view visibility.

## Vault Structure

```
bug-hunting-vault/
├── Targets/           ← One note per target (scope, recon, attack vectors)
├── Techniques/        ← Reusable techniques (Prompt Injection, Bot Bypass, etc.)
└── Progress.md        ← Daily log with wikilinks to targets and techniques
```

## Linking Convention

Every note should link to 2+ other notes so graph view is meaningful:
- Target notes: link to techniques + other targets + tools
- Technique notes: link to applicable targets + related techniques
- Progress log: link to what was worked on that day

## When to Document

During a hunting session, create/update vault notes when:
1. **New target** started — create `Targets/TargetName.md` with scope, DNS, findings
2. **New technique** discovered — create `Techniques/TechniqueName.md`
3. **Interesting finding** — add to the target's attack vectors or techniques
4. **End of session** — update `Progress.md` with what was done and next steps

## Vault Management

- Vault lives at a stable path (/home/who/herd/bug-hunting-vault/)
- Open in Obsidian via "Open folder as vault"
- Graph view icon in left sidebar shows all connections
- Notes are plain markdown — fully portable, no Obsidian lock-in
