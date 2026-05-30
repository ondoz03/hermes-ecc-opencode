# Cross-Platform Interactive Setup — Reference

## Architecture Pattern

The setup scripts use an **interactive menu + mode-based execution** pattern:

```
User runs script → Show menu → Pick mode → Execute steps with auto-check
```

## File Structure

```
ecc-setup.sh     → Linux, macOS, Windows Git Bash (Bash)
ecc-setup.ps1    → Windows PowerShell (PowerShell)
```

## 3-Mode Menu

| Mode | Steps |
|------|-------|
| 1 (Full) | Prerequisites → OpenCode → ECC → Backup → Restore → Init |
| 2 (OpenCode Only) | Prerequisites → OpenCode → ECC → Backup → Init |
| 3 (Hermes Only) | Prerequisites → Backup → Restore |

## Auto-Check Logic

```bash
# Cek OpenCode
if command -v opencode &>/dev/null; then
    ok "Sudah terinstall"
else
    # Install
fi

# Cek ecc-universal
if npm ls -g ecc-universal &>/dev/null; then
    ok "Sudah terinstall"
else
    npm install -g ecc-universal
fi

# Cek backup repo
if [ -d "$BACKUP_DIR/.git" ]; then
    git pull  # update aja
else
    git clone
fi
```

## Cross-Platform Install OpenCode

| Platform | Method | Command |
|----------|--------|---------|
| Linux | curl script | `curl -fsSL https://opencode.ai/install \| bash` |
| macOS | brew | `brew install opencode` |
| Windows | npm | `npm i -g opencode-ai` |
| All (fallback) | npm | `npm i -g opencode-ai` |

## One-Liner Execution

### Linux/macOS:
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/.../main/ecc-setup.sh)"
```

### Windows PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -c "iwr -useb https://raw.githubusercontent.com/.../main/ecc-setup.ps1 | iex"
```

## Path Detection Per OS

```bash
case "$OS" in
  MINGW*|MSYS*|CYGWIN*)
    HERMES_HOME="${USERPROFILE}/.hermes"
    BACKUP_DIR="${USERPROFILE}/hermes-ecc-private"
    ;;
  *)
    HERMES_HOME="$HOME/.hermes"
    BACKUP_DIR="$HOME/hermes-ecc-private"
    ;;
esac
```
