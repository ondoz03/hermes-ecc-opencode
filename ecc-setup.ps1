# ============================================================
# ECC Setup — PUBLIC (Windows PowerShell)
# Simple: install OpenCode + ECC, init project
# No backup/restore — that's in the private repo version
# ============================================================

param(
    [string]$Model = "deepseek-v4-flash",
    [string]$ProjectPath = "."
)

Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   ECC SETUP — PUBLIC (Windows)        ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

function Step($num, $msg) { Write-Host "[$num] $msg" -ForegroundColor Yellow }
function Ok($msg) { Write-Host "   $([char]0x2714)$([char]0xFE0F) $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "   $([char]0x26A0)$([char]0xFE0F) $msg" -ForegroundColor Yellow }
function Fail($msg) { Write-Host "   $([char]0x274C) $msg" -ForegroundColor Red }

function Check-Prereqs {
    Step "1" "Check prerequisites..."
    try { $null = node -v; $null = npm -v } catch { Fail "Node.js/npm not found"; exit 1 }
    try { $null = git --version } catch { Fail "Git not found"; exit 1 }
    Ok "$(node -v) | npm: $(npm -v) | Git OK"
}

function Install-OpenCode {
    Write-Host ""
    Step "2" "OpenCode..."
    try { $ver = opencode --version 2>$null; Ok "Already installed ($ver)"; return } catch {}
    Warn "Not found, installing..."
    try { npm install -g opencode-ai 2>$null; Ok "Installed successfully"; return } catch {}
    Warn "Failed. Manual: npm i -g opencode-ai"
}

function Install-ECC {
    Step "3" "ECC Universal..."
    $globalList = npm ls -g ecc-universal 2>$null
    if ($LASTEXITCODE -eq 0) { Ok "Already installed"; return }
    Warn "Not found, installing..."
    npm install -g ecc-universal 2>$null
    if ($LASTEXITCODE -eq 0) { Ok "ecc-universal installed" } else { Warn "Failed. Manual: npm install -g ecc-universal" }
}

function Init-Project {
    Write-Host ""
    Step "4" "Init OpenCode project..."
    Set-Location $ProjectPath
    $ECC_PKG = "$(npm root -g 2>$null)\ecc-universal"
    if (Test-Path "$ECC_PKG\.opencode") {
        New-Item -ItemType Directory -Force -Path ".opencode" | Out-Null
        Copy-Item "$ECC_PKG\.opencode\*" ".opencode\" -Recurse -Force 2>$null
        @("package.json","package-lock.json","tsconfig.json","MIGRATION.md","README.md","index.ts") | ForEach-Object {
            Remove-Item ".opencode\$_" -Force 2>$null
        }
        Remove-Item ".opencode\dist" -Recurse -Force 2>$null
        $configPath = ".opencode\opencode.json"
        $config = Get-Content $configPath -Raw | ConvertFrom-Json
        $config.model = $Model; $config.small_model = $Model
        foreach ($agent in $config.agent.PSObject.Properties) {
            $agent.Value.PSObject.Properties.Remove('model')
        }
        $config.PSObject.Properties.Remove('plugin')
        $config.instructions = @($config.instructions | Where-Object { $_ -like "instructions/*" })
        $config | ConvertTo-Json -Depth 10 | Set-Content $configPath
        Get-ChildItem ".opencode\commands\*.md" | ForEach-Object {
            (Get-Content $_.FullName) -replace 'agent: everything-claude-code:', 'agent: ' | Set-Content $_.FullName
        }
        Ok "ECC OpenCode ready (model: $Model)"
    } else { Warn "ecc-universal not found" }
}

function Show-Summary {
    $ocOK = try { opencode --version 2>$null; $true } catch { $false }
    $eccOK = npm ls -g ecc-universal 2>$null; $LASTEXITCODE -eq 0
    Write-Host ""
    Write-Host "╔════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║         SETUP COMPLETE! 🎉             ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "   Model:      $Model"
    Write-Host "   OpenCode:   $(if ($ocOK) { '✅' } else { '❌' })"
    Write-Host "   ECC:        $(if ($eccOK) { '✅' } else { '❌' })"
    Write-Host ""
    Write-Host "   Next: opencode"
    Write-Host ""
}

Check-Prereqs
Install-OpenCode
Install-ECC
Init-Project
Show-Summary
