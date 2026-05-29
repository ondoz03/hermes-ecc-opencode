# Obsidian Vault for Bug Hunting

Recommended vault structure for organizing bug bounty research, targets, and methodology.

## Directory Structure

```
📁 Bug-Hunting-Vault/
├── 🎯 Targets/
│   ├── Indeed.md          ← scope, subdomains, DNS, attack vectors
│   ├── GitLab.md          ← mutations, tokens, testing results
│   └── Zendesk.md         ← Zendesk instance recon
├── 📚 Disclosed-Reports/
│   ├── Target-Report-1.md
│   └── Pattern-Library.md
├── ⚔️ Techniques/
│   ├── Prompt-Injection.md
│   ├── IDOR-Checklist.md
│   ├── LLM-Security.md    ← OWASP ASI01-ASI10
│   ├── Bot-Mitigation.md
│   ├── Context7.md        ← MCP docs integration
│   ├── NotebookLM.md      ← Google AI doc analysis
│   └── Tools.md           ← tool inventory
├── 📊 Progress.md         ← daily log with wikilinks
└── 🏆 Bounty.md           ← payout tracker
```

## Key Principles

1. **Interconnected** — every note links to related notes via `[[wikilink]]`
2. **Living docs** — update after every hunting session
3. **Progress log** — chronological with links to relevant notes
4. **Attack vectors first** — each target note lists specific testable vectors

## Wikilink Rules
- Use `[[Note Name]]` (spaces OK, Obsidian resolves)
- Every note references at least 2-3 other notes
- Hub notes (Progress.md) link to all active targets

## Tools Integration
- Obsidian vault lives under `/home/who/herd/bug-hunting-vault/`
- Hermes can read/write notes directly via file tools
- For template creation: `write_file` for new notes
