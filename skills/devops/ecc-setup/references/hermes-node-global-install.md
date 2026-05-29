# Hermes Node vs System Node — npm Global Install

## The Problem
Timpa saat `npm install -g` di terminal, package masuk ke Hermes' Node, bukan system/NVM Node:

```
~/.local/bin/npm → symlink → ~/.hermes/node/bin/npm (Hermes Node v22)
npm root -g → ~/.hermes/node/lib/node_modules/
```

OpenCode (program Go) tidak bisa resolve package dari Hermes' Node modules.

## Node/NPM di PATH
| Path | Source | Version |
|------|--------|---------|
| `~/.local/bin/node` | Hermes (via symlink) | v22.22.3 |
| `~/.local/bin/npm` | Hermes (via symlink) | 10.9.8 |
| `~/.nvm/versions/node/v24.16.0/` | NVM | v24.16.0 |
| `~/.nvm/versions/node/v16.20.2/` | NVM (via `npm16` command) | v16.20.2 |

## Install via NVM (kalo perlu)
```bash
~/.nvm/versions/node/v24.16.0/bin/npm install -g <package>
```

## Solusi untuk OpenCode
Config ECC OpenCode dibuat **self-contained** — tidak perlu npm global:
1. Plugin dihapus dari opencode.json
2. Instructions difilter — cuma refer file lokal
3. Agent didefinisikan langsung di file

## Cek npm mana yang dipakai
```bash
which -a npm           # semua npm di PATH
readlink -f $(which npm)  # resolve symlink
npm root -g            # lokasi global node_modules
```

## Catatan: npm16
File `~/.local/bin/npm16` adalah script untuk pake Node 16 via NVM:
```bash
#!/usr/bin/env bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm use 16 >/dev/null 2>&1
exec npm "$@"
```
