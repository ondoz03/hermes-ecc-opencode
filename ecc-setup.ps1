# ============================================================
# ECC Setup — Windows PowerShell Version
# One command to setup ECC + OpenCode + Hermes restore
#
# Cara pake:
#   powershell -ExecutionPolicy Bypass -File ecc-setup.ps1
#   powershell -ExecutionPolicy Bypass -File ecc-setup.ps1 -Mode 1
#   powershell -ExecutionPolicy Bypass -File ecc-setup.ps1 -Mode 2 -Model gpt-4o
# ============================================================

param(
    [string]$Mode = "",
    [string]$Model = "deepseek-v4-flash",
    [string]$ProjectPath = "."
)

$REPO = "https://github.com/ondoz03/hermes-agent-skill.git"
$BACKUP_DIR = "$env:USERPROFILE\hermes-agent-skill"
$LOCAL_BIN = "$env:USERPROFILE\.local\bin"
$HERMES_HOME = "$env:USERPROFILE\.hermes"

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║         ECC SETUP v2.0 (Windows)      ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Menu interaktif
if ([string]::IsNullOrEmpty($Mode)) {
    Write-Host "Pilih setup:"
    Write-Host ""
    Write-Host "  $([[char]0x1b])[36m1$([[char]0x1b])[0m) Full Setup     — Hermes + OpenCode + ECC (rekomendasi)"
    Write-Host "  $([[char]0x1b])[36m2$([[char]0x1b])[0m) OpenCode Only  — Install/setup OpenCode + ECC"
    Write-Host "  $([[char]0x1b])[36m3$([[char]0x1b])[0m) Hermes Only    — Restore Hermes skills aja"
    Write-Host ""
    $Mode = Read-Host "Pilih [1/2/3] (default: 1)"
    if ([string]::IsNullOrEmpty($Mode)) { $Mode = "1" }
}

if ($Mode -notin @("1","2","3")) { Write-Host "Pilihan tidak valid" -ForegroundColor Red; exit 1 }

$modeName = @{"1"="Full Setup";"2"="OpenCode Only";"3"="Hermes Only"}
Write-Host "Mode: $Mode) $($modeName[$Mode])"
Write-Host ""

# ============================================================
# FUNGSI
# ============================================================

function Step($num, $msg) { Write-Host "[$num] $msg" -ForegroundColor Yellow }
function Ok($msg) { Write-Host "   $([char]0x2714)$([char]0xFE0F) $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "   $([char]0x26A0)$([char]0xFE0F) $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "   $([char]0x274C) $msg" -ForegroundColor Red }

# Prerequisites
function Check-Prereqs {
    Step "1" "Cek prerequisites..."
    try { $null = node -v; $null = npm -v } catch { Fail "Node.js/npm tidak ditemukan"; exit 1 }
    try { $null = git --version } catch { Fail "Git tidak ditemukan"; exit 1 }
    Ok "$(node -v) | npm: $(npm -v) | Git OK"
}

# Install OpenCode
function Install-OpenCode {
    Write-Host ""
    Step "2" "OpenCode..."
    try { $ver = opencode --version 2>$null; Ok "Sudah terinstall ($ver)"; return } catch {}
    Warn "Belum terinstall, menginstall..."
    try { npm install -g opencode-ai 2>$null; Ok "Berhasil terinstall"; return } catch {}
    Warn "Gagal. Manual: npm i -g opencode-ai"
}

# Install ECC
function Install-ECC {
    Step "3" "ECC Universal..."
    $globalList = npm ls -g ecc-universal 2>$null
    if ($LASTEXITCODE -eq 0) { Ok "Sudah terinstall"; return }
    Warn "Belum terinstall, menginstall..."
    npm install -g ecc-universal 2>$null
    if ($LASTEXITCODE -eq 0) { Ok "ecc-universal terinstall" } else { Warn "Gagal. Manual: npm install -g ecc-universal" }
}

# Clone backup
function Clone-Backup {
    Step "4" "Backup repo..."
    if (Test-Path "$BACKUP_DIR\.git") {
        Ok "Sudah ada di $BACKUP_DIR (pull update)"
        Set-Location $BACKUP_DIR; git pull 2>$null
    } else {
        git clone $REPO $BACKUP_DIR
        Ok "Dicloned ke $BACKUP_DIR"
    }
}

# Setup ecc-init
function Setup-ECCInit {
    Step "5" "Script ecc-init..."
    New-Item -ItemType Directory -Force -Path $LOCAL_BIN | Out-Null
    if (Test-Path "$BACKUP_DIR\local-bin\ecc-init") {
        Copy-Item "$BACKUP_DIR\local-bin\ecc-init" "$LOCAL_BIN\ecc-init"
        Ok "Siap di $LOCAL_BIN\ecc-init"
    } else { Warn "Tidak ditemukan" }
}

# Restore Hermes
function Restore-Hermes {
    Write-Host ""
    Step "6" "Restore Hermes..."
    if (Test-Path "$BACKUP_DIR\skills") {
        New-Item -ItemType Directory -Force -Path "$HERMES_HOME\skills" | Out-Null
        Copy-Item "$BACKUP_DIR\skills\*" "$HERMES_HOME\skills\" -Recurse -Force 2>$null
        $count = (Get-ChildItem "$HERMES_HOME\skills" -Recurse -Filter "SKILL.md" 2>$null).Count
        Ok "$count skills"
    }
    if (Test-Path "$BACKUP_DIR\memories") {
        New-Item -ItemType Directory -Force -Path "$HERMES_HOME\memories" | Out-Null
        Copy-Item "$BACKUP_DIR\memories\*" "$HERMES_HOME\memories\" -Recurse -Force 2>$null
        Ok "Memories"
    }
    if (Test-Path "$BACKUP_DIR\config") {
        New-Item -ItemType Directory -Force -Path $HERMES_HOME | Out-Null
        Copy-Item "$BACKUP_DIR\config\*" "$HERMES_HOME\" -Force 2>$null
        Ok "Config"
    }
}

# Init OpenCode project
function Init-Project {
    Write-Host ""
    Step "7" "Init OpenCode project..."
    Set-Location $ProjectPath
    $ECC_PKG = "$(npm root -g 2>$null)\ecc-universal"
    if (Test-Path "$ECC_PKG\.opencode") {
        New-Item -ItemType Directory -Force -Path ".opencode" | Out-Null
        Copy-Item "$ECC_PKG\.opencode\*" ".opencode\" -Recurse -Force 2>$null
        @("package.json","package-lock.json","tsconfig.json","MIGRATION.md","README.md","index.ts") | ForEach-Object {
            Remove-Item ".opencode\$_" -Force 2>$null
        }
        Remove-Item ".opencode\dist" -Recurse -Force 2>$null
        # Fix model + namespace
        $configPath = ".opencode\opencode.json"
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $config.model = $Model; $config.small_model = $Model
        foreach ($agent in $config.agent.PSObject.Properties) {
            $agent.Value.PSObject.Properties.Remove('model')
        }
        $config.PSObject.Properties.Remove('plugin')
        $config.instructions = @($config.instructions | Where-Object { $_ -like "instructions/*" })
        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
        # Fix namespace di command files
        Get-ChildItem ".opencode\commands\*.md" | ForEach-Object {
            (Get-Content $_.FullName) -replace 'agent: everything-claude-code:', 'agent: ' | Set-Content $_.FullName
        }
        Ok "ECC OpenCode ready (model: $Model)"
    } else { Warn "ecc-universal not found" }
}

function Show-Summary {
    $count = (Get-ChildItem "$HERMES_HOME\skills" -Recurse -Filter "SKILL.md" 2>$null).Count
    $ocOK = try { opencode --version 2>$null; $true } catch { $false }
    $eccOK = npm ls -g ecc-universal 2>$null; $LASTEXITCODE -eq 0
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║           SETUP SELESAI! 🎉           ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Model:      $Model"
    Write-Host "   Skills:     $count"
    Write-Host "   OpenCode:   $(if ($ocOK) { '✅' } else { '❌' })"
    Write-Host "   ECC:        $(if ($eccOK) { '✅' } else { '❌' })"
    Write-Host ""
    Write-Host "   Next: opencode"
    Write-Host ""
}

# ============================================================
# EKSEKUSI
# ============================================================

Check-Prereqs

if ($Mode -in @("1","2")) {
    Install-OpenCode
    Install-ECC
    Clone-Backup
    Setup-ECCInit
}

if ($Mode -in @("1","3")) {
    if ($Mode -eq "3") { Clone-Backup }
    Restore-Hermes
}

if ($Mode -in @("1","2")) {
    Init-Project
}

Show-Summary
