# Hermes Skills + ECC OpenCode

**249 skills** untuk Hermes Agent + setup **ECC Universal** untuk OpenCode (Linux, macOS, Windows).

---

## 🚀 Install

### 1 command, semua platform:

```bash
# Linux / macOS / Git Bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-agent-public/main/ecc-setup.sh)"

# Windows PowerShell
powershell -ExecutionPolicy Bypass -c "iwr -useb https://raw.githubusercontent.com/ondoz03/hermes-agent-public/main/ecc-setup.ps1 | iex"
```

Nanti muncul 3 pilihan:
```
1) Full Setup     → Hermes + OpenCode + ECC (rekomendasi)
2) OpenCode Only  → Setup OpenCode + ECC aja  
3) Hermes Only    → Restore 249 skills aja
```

Script otomatis:
- Cek & install **Node.js**, **npm**, **Git** (kalo belum ada)
- Cek & install **OpenCode** (kalo belum ada)
- Cek & install **ecc-universal** (kalo belum ada)
- Clone 249 skill Hermes
- Init `.opencode/` config di project kamu

---

## 🎯 Yang Didapat

### 249 Hermes Skills

| Kategori | Jumlah | Contoh |
|----------|--------|--------|
| **ecc** | 33 skill | `deep-research`, `security-review`, `tdd-workflow`, `api-design` |
| **ecc-agents** | 63 skill | `planner`, `architect`, `code-reviewer`, `security-reviewer` |
| **bug-hunting** | ~45 skill | IDOR, XSS, SSRF, SQLi, GraphQL, LLM injection |
| **creative** | ~17 skill | ASCII art, diagrams, video, music, pixel art |
| **software-dev** | ~12 skill | TDD, debugging, code review, planning |
| **devops** | ~10 skill | Laravel Valet, system diagnostics, MCP |
| Lainnya | ~69 skill | GitHub, research, ML, media, produktivitas |

### 25 OpenCode Agents

Jalanin di terminal pake `/command`:

```
/plan         → Agent planner            /security   → Agent security-reviewer
/tdd          → Agent tdd-guide          /code-review→ Agent code-reviewer
/build-fix    → Agent build-resolver     /e2e        → Agent e2e-runner
/orchestrate  → Multi-agent planner      /verify     → Verification loop
/refactor-clean→ Agent refactor-cleaner  /learn      → Extract patterns
/go-review    → Go review                /go-test    → Go TDD
/rust-review  → Rust review              /update-docs→ Update docs
...dan 14 command lainnya
```

---

## ⚙️ Ganti Model

```bash
# Pake model default (deepseek)
ecc-init

# Atau specify model
ecc-init -m claude-sonnet-4-5
ecc-init -m gpt-4o
ecc-init -m gemini-2.0-flash
ecc-init -m deepseek-v4-flash
```

Semua agent inherit model dari 1 setting — nggak perlu ganti satu-satu.

---

## 📝 Catatan: Node.js & npm

Di laptop kamu mungkin ada beberapa Node.js:

| Command | Lokasi |
|---------|--------|
| `node -v` | Bisa Hermes (v22) atau NVM (v24) tergantung folder |
| `npm install -g` | Masuk ke Node yang aktif saat itu |

Tapi **nggak masalah** — setup script & `ecc-init` udah self-contained. `ecc-universal` cuma perlu buat referensi config aja.

Kalo mau install ke NVM spesifik:
```bash
nvm use 24 && npm install -g ecc-universal
```

---

## 🔄 Pindah PC

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-agent-public/main/ecc-setup.sh)"
```

Pilih `1) Full Setup` → tunggu selesai → `opencode`.

---

## 📦 Repo

```
github.com/ondoz03/hermes-agent-public
├── skills/          249 skill Hermes
├── local-bin/       Script ecc-init
├── reference/       Config OpenCode acuan
├── ecc-setup.sh     Setup script (Linux/macOS/Git Bash)
├── ecc-setup.ps1    Setup script (Windows PowerShell)
└── README.md        Ini
```

Sumber ECC: https://github.com/affaan-m/ECC
