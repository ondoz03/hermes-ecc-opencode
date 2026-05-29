---
name: ecc-setup
description: Complete ECC (Empirical Contextual Computation) setup for Hermes + OpenCode. Repo cloned, 96 skills installed, npm plugin, and ecc-init script. Load this skill when user asks about ECC, affaan-m, agent skills, or cross-harness agent system.
---

# ECC Setup — Complete Reference

ECC (Empirical Contextual Computation) by @affaan-m — cross-harness AI agent operating system. 198k stars, 30k forks on GitHub.

## Repo Location
- `/home/who/herd/ECC/` — 83MB, 2,888 files, v2.0.0-rc.1

## Components
| Item | Count |
|------|-------|
| Agents | 63 |
| Skills (all harnesses) | 249 |
| Skills (Hermes-specific) | 33 |
| Commands | 79 |

## Hermes Skills Installed (96 total)

### Kategori `ecc` (33 skill — dari .agents/skills/)
`deep-research`, `tdd-workflow`, `security-review`, `api-design`, `coding-standards`, `agent-sort`, `brand-voice`, `content-engine`, `backend-patterns`, `frontend-patterns`, `mcp-server-patterns`, `verification-loop`, `eval-harness`, `e2e-testing`, `crosspost`, `x-api`, `exa-search`, `fal-ai-media`, `market-research`, `investor-materials`, `investor-outreach`, `article-writing`, `frontend-slides`, `bun-runtime`, `nextjs-turbopack`, `product-capability`, `strategic-compact`, `agent-introspection-debugging`, `dmux-workflows`, `documentation-lookup`, `everything-claude-code`, `mle-workflow`, `video-editing`

### Kategori `ecc-agents` (63 skill — konversi dari agents/)
Semua agent dari folder `agents/` dikonversi ke format SKILL.md Hermes:
`planner`, `architect`, `code-reviewer`, `security-reviewer`, `tdd-guide`, `build-error-resolver`, `e2e-runner`, `doc-updater`, `refactor-cleaner`, `database-reviewer`, `python-reviewer`, `rust-reviewer`, `rust-build-resolver`, `go-reviewer`, `go-build-resolver`, `java-reviewer`, `java-build-resolver`, `typescript-reviewer`, `react-reviewer`, `react-build-resolver`, `cpp-reviewer`, `cpp-build-resolver`, `kotlin-reviewer`, `kotlin-build-resolver`, `swift-reviewer`, `swift-build-resolver`, `dart-build-resolver`, `flutter-reviewer`, `csharp-reviewer`, `fsharp-reviewer`, `django-reviewer`, `django-build-resolver`, `fastapi-reviewer`, `mle-reviewer`, `pytorch-build-resolver`, `loop-operator`, `harness-optimizer`, `docs-lookup`, `pr-test-analyzer`, `silent-failure-hunter`, `performance-optimizer`, `seo-specialist`, `marketing-agent`, `network-architect`, `network-config-reviewer`, `network-troubleshooter`, `homelab-architect`, `healthcare-reviewer`, `code-architect`, `code-explorer`, `code-simplifier`, `comment-analyzer`, `conversation-analyzer`, `chief-of-staff`, `a11y-architect`, `opensource-forker`, `opensource-packager`, `opensource-sanitizer`, `type-design-analyzer`, `gan-evaluator`, `gan-generator`, `gan-planner`, `harmonyos-app-resolver`

## OpenCode Setup

### ⚠️ PENTING: Plugin-only config TIDAK cukup
Config minimal `{"plugin": ["ecc-universal"]}` **tidak akan mendaftarkan agent atau command** ke OpenCode. Command `/security`, `/plan`, dll. tidak akan muncul.

OpenCode butuh definisi lengkap agent dan command di `opencode.json` — bukan cuma referensi plugin.

### Cara Benar

**Opsi A — Copy seluruh .opencode dari package (recommended):**
```bash
rm -rf .opencode
cp -r /home/who/.hermes/node/lib/node_modules/ecc-universal/.opencode/ .opencode/
```

**Opsi B — Gunakan script ecc-init (sudah diupdate):**
```bash
ecc-init
```
Ini akan copy config lengkap dari package + prompts + commands.

**Opsi C — Pakai full ECC repo (paling lengkap, 63 agent bukan 25):**
```bash
cp -r /home/who/herd/ECC/.opencode/* .opencode/
```
ECC repo punya lebih banyak agent definitions di `.opencode/opencode.json` daripada npm package.

### Agent & Command Package vs Repo
| Sumber | Agents | Commands |
|--------|--------|----------|
| npm `ecc-universal@1.10.0` | 25 | 26 |
| ECC repo `v2.0.0-rc.1` | 63 | 79 |

Package cocok untuk setup cepat, repo untuk yang mau lengkap.

### Models
Default agent pake model `anthropic/claude-opus-4-5`. **Wajib disesuaikan** kalo provider kamu bukan Anthropic.

**Fix otomatis dengan ecc-init -m:**
Script `~/.local/bin/ecc-init` support flag `-m` atau `--model`:
```bash
ecc-init                          # pake default (deepseek-v4-flash)
ecc-init -m claude-sonnet-4-5    # pake Claude
ecc-init -m gpt-4o               # pake OpenAI
ecc-init -m gemini-2.0-flash     # pake Gemini
ecc-init -m deepseek-v4-flash /path/to/project  # folder tertentu
```
Script otomatis ganti semua model Claude → model yang dipilih di seluruh opencode.json (termasuk 25 agent).

## Dashboard
```bash
cd /home/who/herd/ECC
npm run dashboard
```
Atau: `python3 ecc_dashboard.py`

## Cara Pakai di Hermes
Skill ECC auto-load sesuai deskripsi. Cukup bilang tugasnya.
Kalo mau paksa skill tertentu: "Pake skill <nama> buat ini" atau "Pake agent <nama>".

## Troubleshooting OpenCode

### "Model X is not valid" Error
**Penyebab:** ECC's `opencode.json` default pake model Claude (`claude-sonnet-4-5`, `claude-opus-4-5`, `claude-haiku-4-5`). Kalo provider kamu bukan Anthropic, model ini error.

**Fix dengan ecc-init -m (recommended):**
```bash
cd project-anda
ecc-init -m deepseek-v4-flash     # atau model kamu
ecc-init -m gpt-4o                # OpenAI
ecc-init -m claude-sonnet-4-5     # Claude
```
Script otomatis ganti semua model di opencode.json.

**Fix model default (biar nggak perlu -m tiap kali):**
Edit baris `MODEL=` di `~/.local/bin/ecc-init`:
```bash
nano ~/.local/bin/ecc-init
# Ubah baris 7: MODEL="deepseek-v4-flash"
# Simpen. Selanjutnya cukup: ecc-init (tanpa -m) di project baru
```

**Fix manual via sed:**
```bash
cd project
sed -i 's/claude-sonnet-4-5/deepseek-v4-flash/g' .opencode/opencode.json
sed -i 's/claude-opus-4-5/deepseek-v4-flash/g' .opencode/opencode.json
sed -i 's/claude-haiku-4-5/deepseek-v4-flash/g' .opencode/opencode.json
```

### Command /security (atau lainnya) tidak muncul
**Penyebab:** Config `{"plugin": ["ecc-universal"]}` MINIMAL tidak mendaftarkan agent/command. OpenCode butuh definisi lengkap di `opencode.json`.

**Fix:** Gunakan full config dari package:
```bash
rm -rf .opencode && ecc-init
```

### Plugin vs Package: 25 vs 63 Agent
| Sumber | Agents | Commands |
|--------|--------|----------|
| npm `ecc-universal@1.10.0` | 25 | 26 |
| ECC repo `v2.0.0-rc.1` | 63 | 79 |

Package cocok setup cepat. Kalo mau lengkap (63 agent), copy dari repo:
```bash
cp -r /home/who/herd/ECC/.opencode/* .opencode/
```

## Backup & Cron — Daily Self-Backup
Setiap hari jam 05:00, Hermes backup dirinya sendiri ke GitHub.

### System Backup
- **GitHub Repo:** `https://github.com/ondoz03/hermes-agent-skill.git`
- **Isi Backup:** 249 skills, memories, config Hermes, scripts
- **Cron:** `0 5 * * *` — job name "ECC Daily Backup"

### Script Backup
**File:** `~/.local/bin/ecc-backup-daily.sh`
Juga di-copy ke: `~/.hermes/scripts/ecc-backup-daily.sh`

**Cara kerja:**
1. rsync skills/ dari `~/.hermes/skills/` ke `~/hermes-agent-skill/skills/`
2. rsync memories/ dari `~/.hermes/memories/` ke repo
3. Copy config (config.yaml, .env)
4. git add + git commit + git push ke GitHub

**Jalankan manual:**
```bash
bash ~/.local/bin/ecc-backup-daily.sh
```
Log: `/tmp/hermes-backup-YYYYMMDD.log`

### Restore di PC Baru
```bash
# Clone repo
git clone https://github.com/ondoz03/hermes-agent-skill.git

# Restore skills
cp -r hermes-agent-skill/skills/* ~/.hermes/skills/

# Restore memories
cp -r hermes-agent-skill/memories/* ~/.hermes/memories/

# Restore config
cp hermes-agent-skill/config/* ~/.hermes/

# Restore scripts
cp hermes-agent-skill/local-bin/* ~/.local/bin/

# Install ECC plugin
npm install -g ecc-universal
```

## Reference Files
- `references/agent-conversion.md` — Python script & technique untuk convert Claude Code agents ke Hermes SKILL.md format
- `references/opencode-plugin-setup.md` — Detail cara setup OpenCode dengan ECC, pitfalls, dan beda plugin vs agent config
- `references/cross-platform-ecc-init.md` — Cross-platform guide: setup ecc-init di Linux, macOS, Windows CMD, dan PowerShell, termasuk cara ganti model dan PATH

