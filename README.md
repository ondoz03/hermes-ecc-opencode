# Hermes Agent — Skills & ECC Setup

Backup lengkap **249 skill Hermes**, memory, konfigurasi, dan panduan setup **ECC Universal + OpenCode** untuk Windows, macOS, dan Linux.

---

## 🚀 Quick Start (One Command)

Install semua — ECC, skill Hermes, OpenCode config — dalam 1 perintah.

### 🐧 Linux / macOS
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-agent-skill/main/ecc-setup.sh)"
```

Kustom model & path:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-agent-skill/main/ecc-setup.sh)" -- gpt-4o /path/project
```

### 🪟 Windows (PowerShell)
```powershell
powershell -ExecutionPolicy Bypass -c "iwr -useb https://raw.githubusercontent.com/ondoz03/hermes-agent-skill/main/ecc-setup.ps1 | iex"
```

Atau download dulu:
```powershell
Invoke-WebRequest -Uri https://raw.githubusercontent.com/ondoz03/hermes-agent-skill/main/ecc-setup.ps1 -OutFile ecc-setup.ps1
powershell -ExecutionPolicy Bypass -File ecc-setup.ps1 -Model deepseek-v4-flash
```

### 🪟 Windows (Git Bash)
```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-agent-skill/main/ecc-setup.sh)
```

### ✅ Yang didapat
| Komponen | Status |
|----------|--------|
| 249 Hermes skills | ✅ Restore |
| ecc-universal (25 agents) | ✅ Install |
| ecc-init script | ✅ Setup |
| OpenCode config (fix namespace) | ✅ Init |
| Model diset sesuai pilihan | ✅ |

---

## ⚠️ Masalah: Hermes Node vs Global Install

**Masalahnya:** Hermes Agent punya Node.js sendiri:

```
~/.local/bin/node → symlink → ~/.hermes/node/bin/node   (Hermes Node v22)
~/.local/bin/npm  → symlink → ~/.hermes/node/bin/npm    (Hermes npm)
```

Jadi setiap `npm install -g` selalu masuk ke Hermes:
```
~/.hermes/node/lib/node_modules/   ← tempat npm global
```

Tapi **OpenCode adalah program Go** — dia nggak tahu path Node Hermes. 
Makanya kalo config opencode.json pake `"plugin": ["ecc-universal"]`, 
OpenCode nggak bisa menemukan package-nya.

**Catatan:** Kalo kamu pake NVM (Node Version Manager), beberapa project 
pake Node versi beda. Cek dengan `node -v` di folder project:
```
~/.nvm/versions/node/v24.16.0/    ← NVM Node 24
~/.nvm/versions/node/v16.20.2/    ← NVM Node 16 (via npm16)
```

Tapi untuk ECC OpenCode, solusinya bukan install ulang ke NVM — 
tapi bikin config yang **self-contained**.

---

## ✅ Solusi: Self-Contained Config

Config opencode.json udah di-fix:

1. **Plugin dihapus** — agent didefinisikan langsung di file
2. **Instructions difilter** — cuma refer file lokal di `.opencode/`
3. **Model di 1 tempat** — semua agent inherit dari parent

Jadi **nggak perlu `npm install -g ecc-universal`** sama sekali.

---

## 📦 Isi Repo

| Folder | Isi |
|--------|-----|
| [`skills/`](./skills/) | 249 skill Hermes (ecc, ecc-agents, bug-hunting, devops, dll) |
| [`memories/`](./memories/) | Memory persisten Hermes |
| [`config/`](./config/) | Config Hermes (`config.yaml`, `.env`) |
| [`local-bin/`](./local-bin/) | Script `ecc-init` (copy & paste isinya di PC kamu) |
| [`reference/`](./reference/) | Config OpenCode acuan (`opencode.json`) |
| [`notes/`](./notes/) | Catatan ECC repo & cara install |

---

## 🚀 Setup ECC untuk OpenCode

### 1. Install ecc-universal (Opsional — nggak wajib)

Ini cuma kalo kamu mau pake plugin hooks tambahan.

**Via Hermes (default npm):**
```bash
npm install -g ecc-universal
```
📍 Masuk ke: `~/.hermes/node/lib/node_modules/ecc-universal/`

**Via NVM (kalo NVM aktif):**
```bash
nvm use 24
npm install -g ecc-universal
```
📍 Masuk ke: `~/.nvm/versions/node/v24.16.0/lib/node_modules/`

### 2. Setup ecc-init (Wajib — biar gampang)

Bikin file `~/.local/bin/ecc-init`:

<details>
<summary>📄 Klik lihat isi ecc-init</summary>

```bash
#!/bin/bash
# ECC Init untuk OpenCode
# Copy config lengkap dari ecc-universal package
set -euo pipefail

# ⚙️ DEFAULT MODEL — Ganti kalo mau default beda
DEFAULT_MODEL="deepseek-v4-flash"
# ============================================

ECC_PKG="$HOME/.hermes/node/lib/node_modules/ecc-universal"
DIR="."
MODEL="$DEFAULT_MODEL"

# Parse argumen
while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model)
      MODEL="$2"
      shift 2
      ;;
    -h|--help)
      echo "Cara pake: ecc-init [-m|--model <nama-model>] [direktori]"
      echo ""
      echo "Contoh:"
      echo "  ecc-init                          # pake model default"
      echo "  ecc-init -m claude-sonnet-4-5     # pake Claude"
      echo "  ecc-init -m gpt-4o                # pake OpenAI"
      echo "  ecc-init -m gemini-2.0-flash      # pake Gemini"
      exit 0
      ;;
    *)
      DIR="$1"
      shift
      ;;
  esac
done

if [ ! -d "$ECC_PKG" ]; then
  echo "❌ ecc-universal belum terinstall."
  echo "   Install dulu: npm install -g ecc-universal"
  echo "   Atau jalankan dari folder ECC yang sudah di-clone."
  exit 1
fi

if [ -f "$DIR/.opencode/opencode.json" ]; then
  echo "⚠️  $DIR/.opencode/ sudah ada."
  echo "   Hapus dulu: rm -rf $DIR/.opencode"
  echo "   Terus jalanin ulang: ecc-init -m $MODEL"
  exit 0
fi

mkdir -p "$DIR/.opencode"
cp -r "$ECC_PKG/.opencode/"* "$DIR/.opencode/"

rm -f "$DIR/.opencode/package.json" "$DIR/.opencode/package-lock.json" \
      "$DIR/.opencode/tsconfig.json" "$DIR/.opencode/MIGRATION.md" \
      "$DIR/.opencode/README.md" "$DIR/.opencode/index.ts" \
      "$DIR/.opencode/dist"

# Bersihin & set model
python3 -c "
import json
path = '$DIR/.opencode/opencode.json'
d = json.load(open(path))
d['model'] = '$MODEL'
d['small_model'] = '$MODEL'
# Hapus model dari agent biar inherit dari parent
for name, agent in d.get('agent', {}).items():
    agent.pop('model', None)
# Hapus plugin (biar nggak depend on module resolution)
d.pop('plugin', None)
# Filter instructions — cuma yang ada di .opencode/ aja
d['instructions'] = [i for i in d.get('instructions', []) if i.startswith('instructions/')]
json.dump(d, open(path, 'w'), indent=2)
"

echo "✅ ECC OpenCode ready for $(basename "$(cd "$DIR" && pwd)")"
echo "   Model: $MODEL (semua agent inherit dari parent)"
echo ""
echo "   Command: /plan /tdd /code-review /security /build-fix"
echo "            /e2e /refactor-clean /orchestrate /learn /verify"
echo "   ...dan 16 command lainnya"
```

</details>

```bash
chmod +x ~/.local/bin/ecc-init
```

### 3. Cara Pake

```bash
cd project-anda
ecc-init -m deepseek-v4-flash
opencode
```

### 4. Ganti Model

```bash
ecc-init -m claude-sonnet-4-5
ecc-init -m gpt-4o
ecc-init -m gemini-2.0-flash
```

---

## 🎯 Command OpenCode

| Command | Fungsi | Agent |
|---------|--------|-------|
| `/plan` | Planning fitur | planner |
| `/tdd` | TDD workflow | tdd-guide |
| `/code-review` | Review kode | code-reviewer |
| `/security` | Audit keamanan | security-reviewer |
| `/build-fix` | Fix build error | build-error-resolver |
| `/e2e` | E2E testing | e2e-runner |
| `/refactor-clean` | Bersihin dead code | refactor-cleaner |
| `/orchestrate` | Multi-agent | planner |
| `/learn` | Extract patterns | — |
| `/verify` | Verification loop | — |
| +18 command lainnya | | |

---

## 🔄 Restore Semua (Pindah PC)

```bash
# 1. Clone repo
git clone https://github.com/ondoz03/hermes-agent-skill.git

# 2. Install Hermes & ECC
npm install -g ecc-universal

# 3. Copy skill & memory
cp -r hermes-agent-skill/skills/* ~/.hermes/skills/
cp -r hermes-agent-skill/memories/* ~/.hermes/memories/
cp hermes-agent-skill/config/* ~/.hermes/
cp hermes-agent-skill/local-bin/* ~/.local/bin/

# 4. Siap dipake
ecc-init -m deepseek-v4-flash
```

---

## 🛠️ Troubleshooting

**Agent build's configured model not valid**
→ Ganti model: `ecc-init -m <model-anda>`

**Command not found**
→ Reset: `rm -rf .opencode && ecc-init`

**npm install -g masuk ke Hermes bukan sistem**
→ Itu normal karena symlink. Tapi config kita self-contained, jadi nggak masalah.
→ Kalo mau pake NVM: `nvm use 24 && npm install -g ecc-universal`

---

## 📚 Sumber

- **ECC:** https://github.com/affaan-m/ECC
- **Hermes:** https://hermes-agent.nousresearch.com/docs
- **OpenCode:** https://opencode.ai
