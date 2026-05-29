# Cross-Platform ECC Setup Scripts

## Linux / macOS / Git Bash — `ecc-setup.sh`

Script bash tunggal yang:
- Mendeteksi OS (Linux, macOS, Windows via Git Bash)
- Clone backup repo dari GitHub
- Install `ecc-universal` via npm global
- Setup `ecc-init` ke `~/.local/bin/`
- Restore 249 Hermes skills + memories + config
- Init OpenCode project dengan model yang dipilih

```bash
# Default (deepseek-v4-flash)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-agent-skill/main/ecc-setup.sh)"

# Custom model + path
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ondoz03/hermes-agent-skill/main/ecc-setup.sh)" -- gpt-4o /path/project
```

## Windows PowerShell — `ecc-setup.ps1`

```powershell
powershell -ExecutionPolicy Bypass -c "iwr -useb https://raw.githubusercontent.com/ondoz03/hermes-agent-skill/main/ecc-setup.ps1 | iex"
```

## Path per Platform
| Platform | Hermes Home | Backup Dir |
|----------|-------------|------------|
| Linux/macOS | `~/.hermes/` | `~/hermes-agent-skill` |
| Windows | `%USERPROFILE%\.hermes\` | `%USERPROFILE%\hermes-agent-skill` |

## 6 Langkah
1. Cek node, npm, git
2. Clone backup repo
3. Install ecc-universal global
4. Copy ecc-init ke local bin
5. Restore skills + memories + config
6. Init project dengan model

## Fallback
Jika ecc-universal gagal install (Hermes Node vs system Node), script kasih instruksi manual. Config OpenCode dibuat self-contained jadi tidak benar-benar butuh package.
