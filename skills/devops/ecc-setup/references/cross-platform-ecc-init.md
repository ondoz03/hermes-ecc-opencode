# Cross-Platform ecc-init Setup

Reference for setting up ecc-init on Windows, macOS, and Linux. ECC OpenCode plugin (`ecc-universal`) works on all platforms, but the init script differs per OS.

---

## 📦 Install ecc-universal (all platforms)

```bash
npm install -g ecc-universal
```

Verify:
```bash
npm ls -g ecc-universal
```

---

## 🐧 Linux ecc-init

**Location:** `~/.local/bin/ecc-init`

**Make executable:**
```bash
chmod +x ~/.local/bin/ecc-init
```

**Features:**
- Supports `-m / --model` flag: `ecc-init -m gpt-4o`
- Auto-detects package path under `$HOME/.hermes/node/lib/node_modules/ecc-universal`
- Replaces Claude model strings with user's model

**Ensure PATH:**
```bash
# Check if ~/.local/bin is in PATH
echo "$PATH" | grep -q ".local/bin" && echo "in PATH" || echo "not in PATH"

# If not, add to ~/.bashrc or ~/.zshrc (bawaan Ubuntu 24.04 sudah include)
```

---

## 🍎 macOS ecc-init

**Location:** `~/.local/bin/ecc-init` (sama kaya Linux)

**Package path berbeda:** Di macOS, npm global biasanya di:
```
~/.npm-global/lib/node_modules/ecc-universal
```
Atau kalo pake Homebrew Node:
```
/usr/local/lib/node_modules/ecc-universal
```

**Update `ECC_PKG` di script:**
```bash
# Di baris 10-11 ecc-init, ganti jadi:
ECC_PKG="$HOME/.npm-global/lib/node_modules/ecc-universal"
```

**Make executable:**
```bash
chmod +x ~/.local/bin/ecc-init
```

---

## 🪟 Windows CMD ecc-init

**Location:** `C:\Users\<username>\.local\bin\ecc-init.bat`

```bat
@echo off
set MODEL=%1
if "%MODEL%"=="" set MODEL=deepseek-v4-flash
if not exist ".opencode" mkdir .opencode
copy /y "%APPDATA%\npm\node_modules\ecc-universal\.opencode\opencode.json" .opencode\
powershell -Command "(Get-Content .opencode\opencode.json) -replace 'claude-sonnet-4-5', '%MODEL%' -replace 'claude-opus-4-5', '%MODEL%' -replace 'claude-haiku-4-5', '%MODEL%' | Set-Content .opencode\opencode.json"
echo ✅ ECC ready with model: %MODEL%
```

**Usage:**
```bat
cd C:\Users\...\project
ecc-init.bat deepseek-v4-flash
ecc-init.bat gpt-4o
ecc-init.bat claude-sonnet-4-5
```

**Add to PATH:**
```
1. Win + X → System → Advanced system settings
2. Environment Variables → User variables → Path → Edit
3. Add: C:\Users\<username>\.local\bin\
4. OK, restart CMD
```

---

## 🪟 Windows PowerShell ecc-init

**Location:** `C:\Users\<username>\Documents\WindowsPowerShell\Scripts\ecc-init.ps1` (atau folder mana pun di PATH)

```powershell
param([string]$model = "deepseek-v4-flash")
$pkg = "$env:APPDATA\npm\node_modules\ecc-universal\.opencode"
if (-not (Test-Path ".opencode")) { mkdir .opencode }
Copy-Item "$pkg\opencode.json" ".opencode\"
(Get-Content ".opencode\opencode.json") -replace 'claude-sonnet-4-5', $model -replace 'claude-opus-4-5', $model -replace 'claude-haiku-4-5', $model | Set-Content ".opencode\opencode.json"
Write-Host "✅ ECC ready with model: $model"
```

**Usage:**
```powershell
cd C:\Users\...\project
.\ecc-init.ps1
.\ecc-init.ps1 -model gpt-4o
```

---

## ⚙️ Model Parameter

Semua script di atas nerima `-m <model>` atau `--model <model>` untuk specify model AI.

**Contoh model yang umum:**
| Provider | Model Name |
|----------|-----------|
| DeepSeek | `deepseek-v4-flash`, `deepseek/deepseek-chat` |
| OpenAI | `gpt-4o`, `gpt-4o-mini`, `gpt-4-turbo` |
| Anthropic | `claude-sonnet-4-5`, `claude-opus-4-5`, `claude-haiku-4-5` |
| Google | `gemini-2.0-flash`, `gemini-2.0-pro` |
| OpenRouter | `openai/gpt-4o`, `anthropic/claude-sonnet-4-5` |
| Groq | `groq/llama-3.3-70b`, `groq/deepseek-r1` |

Ganti model kapan aja dengan jalanin ulang `ecc-init -m <model>` di project.

---

## 🔧 Manual Tanpa Script

Kalo nggak mau pake script, cukup:

**1. Copy opencode.json dari package:**
```bash
# Linux
cp ~/.hermes/node/lib/node_modules/ecc-universal/.opencode/opencode.json .opencode/

# macOS
cp ~/.npm-global/lib/node_modules/ecc-universal/.opencode/opencode.json .opencode/

# Windows (PowerShell)
Copy-Item "$env:APPDATA\npm\node_modules\ecc-universal\.opencode\opencode.json" ".opencode\"
```

**2. Ganti model:**
```bash
sed -i 's/claude-sonnet-4-5/<model-anda>/g' .opencode/opencode.json
sed -i 's/claude-opus-4-5/<model-anda>/g' .opencode/opencode.json
sed -i 's/claude-haiku-4-5/<model-anda>/g' .opencode/opencode.json
```
