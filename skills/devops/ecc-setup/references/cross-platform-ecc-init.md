# Cross-Platform ECC Init Guide

Setup ECC + OpenCode di Linux, macOS, Windows.

## Prerequisite

```bash
npm install -g ecc-universal
```

## ECC Init Script Per Platform

### Linux / macOS

File: `~/.local/bin/ecc-init`

```bash
#!/bin/bash
set -euo pipefail

DEFAULT_MODEL="deepseek-v4-flash"

ECC_PKG="$HOME/.hermes/node/lib/node_modules/ecc-universal"
DIR="."
MODEL="$DEFAULT_MODEL"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model) MODEL="$2"; shift 2 ;;
    -h|--help)
      echo "Cara pake: ecc-init [-m model] [direktori]"
      echo "  ecc-init -m gpt-4o"
      echo "  ecc-init -m claude-sonnet-4-5"
      exit 0
      ;;
    *) DIR="$1"; shift ;;
  esac
done

[ -d "$ECC_PKG" ] || { echo "Install dulu: npm install -g ecc-universal"; exit 1; }
[ -f "$DIR/.opencode/opencode.json" ] && { echo "Already exists, rm -rf .opencode first"; exit 0; }

mkdir -p "$DIR/.opencode"
cp -r "$ECC_PKG/.opencode/"* "$DIR/.opencode/"
rm -f "$DIR/.opencode/package.json" "$DIR/.opencode/package-lock.json" \
      "$DIR/.opencode/tsconfig.json" "$DIR/.opencode/MIGRATION.md" \
      "$DIR/.opencode/README.md"

# Python JSON parsing — jangan sed
python3 -c "
import json
d = json.load(open('$DIR/.opencode/opencode.json'))
d['model'] = '$MODEL'
d['small_model'] = '$MODEL'
for a in d.get('agent', {}).values(): a.pop('model', None)
json.dump(d, open('$DIR/.opencode/opencode.json', 'w'), indent=2)
"

echo "ECC ready: $(basename $(cd $DIR && pwd)) [model: $MODEL]"
```

Buat executable:
```bash
chmod +x ~/.local/bin/ecc-init
```

Pastikan `~/.local/bin` ada di PATH:
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
# atau ~/.zshrc
```

### Windows CMD

File: `C:\Users\<nama>\.local\bin\ecc-init.bat`

```bat
@echo off
set MODEL=%1
if "%MODEL%"=="" set MODEL=deepseek-v4-flash
if not exist ".opencode" mkdir .opencode
copy /y "%APPDATA%\npm\node_modules\ecc-universal\.opencode\opencode.json" .opencode\
copy /y "%APPDATA%\npm\node_modules\ecc-universal\.opencode\prompts" .opencode\prompts\
copy /y "%APPDATA%\npm\node_modules\ecc-universal\.opencode\commands" .opencode\commands\
powershell -Command "(Get-Content .opencode\opencode.json) -replace '\"model\": \"[^\"]+\"', '\"model\": \"%MODEL%\"' -replace '\"small_model\": \"[^\"]+\"', '\"small_model\": \"%MODEL%\"' | Set-Content .opencode\opencode.json"
echo ECC ready with model: %MODEL%
```

### Windows PowerShell

File: `C:\Users\<nama>\Documents\WindowsPowerShell\Scripts\ecc-init.ps1`

```powershell
param([string]$model = "deepseek-v4-flash")
$pkg = "$env:APPDATA\npm\node_modules\ecc-universal\.opencode"
if (-not (Test-Path ".opencode")) { mkdir .opencode -Force }
Copy-Item "$pkg\opencode.json" ".opencode\"
if (Test-Path "$pkg\prompts") { Copy-Item "$pkg\prompts" ".opencode\" -Recurse }
if (Test-Path "$pkg\commands") { Copy-Item "$pkg\commands" ".opencode\" -Recurse }
$json = Get-Content ".opencode\opencode.json" -Raw
$json = $json -replace '"model": "[^"]+"', '"model": "' + $model + '"'
$json = $json -replace '"small_model": "[^"]+"', '"small_model": "' + $model + '"'
$json | Set-Content ".opencode\opencode.json"
Write-Host "ECC ready with model: $model"
```

## PATH Setup

### Linux
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

### macOS
```bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```
Atau pake `~/.bash_profile`.

### Windows
PowerShell:
```powershell
$path = [Environment]::GetEnvironmentVariable("Path", "User")
$newPath = "$env:USERPROFILE\.local\bin"
if ($path -notlike "*$newPath*") {
  [Environment]::SetEnvironmentVariable("Path", "$path;$newPath", "User")
}
```

CMD:
```cmd
setx PATH "%PATH%;%USERPROFILE%\.local\bin"
```

## Usage

```bash
# Init project dengan default model
cd my-project
ecc-init

# Init dengan model tertentu
ecc-init -m gpt-4o
ecc-init -m claude-sonnet-4-5
ecc-init -m deepseek-v4-flash

# Init di folder tertentu
ecc-init -m gpt-4o /path/to/project
```

## Verify

```bash
cd my-project
cat .opencode/opencode.json | grep '"model"'
# Harusnya: "model": "deepseek-v4-flash" (atau model yang dipilih)
```
