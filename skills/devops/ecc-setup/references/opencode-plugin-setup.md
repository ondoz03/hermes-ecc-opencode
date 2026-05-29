# OpenCode + ECC Plugin Setup

## Architecture

ECC provides two ways to use agents in OpenCode:

| Approach | What it provides |
|----------|-----------------|
| **Plugin** (`"plugin": ["ecc-universal"]`) | Plugin hooks, custom tools dari package |
| **Config** (agent/command definitions di opencode.json) | Agent definitions, commands, prompts |

**Config `"plugin": ["ecc-universal"]` SAJA tidak cukup.** OpenCode butuh definisi agent dan command di `opencode.json` agar `/security`, `/plan`, dll bisa dipanggil.

## ⚠️ Plugin HARUS Dihapus

**Masalah:** `opencode.json` asli punya `"plugin": ["./plugins"]` yang:
- Refer local plugin folder `./plugins` (relatif ke `.opencode/`)
- Plugin hooks error karena OpenCode (Go binary) gagal resolve module path
- Menyebabkan agent namespace error: `everything-claude-code:code-reviewer`

**Solusi:** Hapus `plugin` dari `opencode.json`:
```python
d.pop('plugin', None)
```

Agent udah didefinisikan langsung di `opencode.json` — plugin hooks nggak diperlukan.

## ⚠️ Instructions HARUS Difilter

**Masalah:** `opencode.json` asli punya 14 instruction paths, sebagian besar refer file di root package (`AGENTS.md`, `CONTRIBUTING.md`, `skills/*/SKILL.md`). File-file ini TIDAK ADA di project user.

**Solusi:** Filter instructions — cuma yang ada di `.opencode/instructions/`:
```python
d['instructions'] = [i for i in d.get('instructions', []) if i.startswith('instructions/')]
```

## CRITICAL: Agent-Level Model Removal

**Masalah:** `opencode.json` asli mendefinisikan model di tiap agent. Saat pindah provider, 25+ model perlu diubah satu-satu.

**Solusi:** Hapus `model` dari semua agent, biarkan inherit dari parent:
```json
{
  "model": "deepseek-v4-flash",  // ← satu-satunya tempat define model
  "agent": {
    "planner": { ... },          // ← model dihapus, inherit
    "security-reviewer": { ... } // ← model dihapus, inherit
  }
}
```

**Cara implementasi (Python, jangan sed):**
```python
import json
path = '.opencode/opencode.json'
d = json.load(open(path))
d['model'] = 'model-anda'
d['small_model'] = 'model-anda'
for name, agent in d.get('agent', {}).items():
    agent.pop('model', None)
d.pop('plugin', None)
d['instructions'] = [i for i in d.get('instructions', []) if i.startswith('instructions/')]
json.dump(d, open(path, 'w'), indent=2)
```

Ini yang dilakukan `ecc-init -m <model>` — semua fix dalam 1 langkah.

## Kenapa sed Bermasalah

Original: `"model": "anthropic/claude-sonnet-4-5"`

| Operation | Result | Status |
|-----------|--------|--------|
| `sed 's/claude-sonnet-4-5/gpt-4o/g'` | `"model": "anthropic/gpt-4o"` | ❌ Sisa `anthropic/` prefix |
| `sed 's/anthropic\/claude-sonnet-4-5/gpt-4o/g'` | OK | ✅ Tapi fragile |
| Python JSON parsing | Clean replace | ✅ Aman |

**Kesimpulan: Jangan pernah pakai sed untuk replace di JSON struktural.**

## Agent Not Found Error (namespace)

Error: `Agent not found: "everything-claude-code:code-reviewer"`

**Penyebab:** Plugin `./plugins` menyebabkan OpenCode mencari agent dengan namespace plugin, bukan dari definisi lokal di opencode.json.

**Fix:** Hapus plugin dari config + filter instructions + reset:
```bash
rm -rf .opencode
ecc-init -m <model-kamu>
```

## Node.js Duality — Hermes vs Sistem

**Masalah:** `~/.local/bin/npm` adalah symlink ke `~/.hermes/node/bin/npm` (Hermes' Node). Semua `npm install -g` masuk ke Hermes' node_modules, bukan sistem.

```
~/.local/bin/node → ~/.hermes/node/bin/node   (Hermes Node v22)
~/.local/bin/npm  → ~/.hermes/node/bin/npm     (Hermes npm)
```

NVM juga terinstall: `~/.nvm/versions/node/v24.16.0/bin/npm`

**Dampak ke OpenCode:** Jika `opencode.json` punya `"plugin": ["ecc-universal"]`, OpenCode (Go binary) coba load npm module via sistem Node — yang gagal karena package cuma ada di Hermes' node_modules.

**Solusi terbaru:** Hapus plugin + filter instructions → config self-contained, tidak perlu npm global.

**Kalo butuh install npm package untuk keperluan lain dengan Node luar:**
```bash
~/.nvm/versions/node/v24.16.0/bin/npm install -g <package>
```

## 25 vs 63 Agents

| Source | Agents | Commands | Notes |
|--------|--------|----------|-------|
| npm `ecc-universal@1.10.0` `.opencode/opencode.json` | 25 | 26 | Setup cepat, model ringan |
| ECC repo `v2.0.0-rc.1` `.opencode/opencode.json` | 63 | 79 | Lebih lengkap |

Package cukup untuk sebagian besar workflow. Gunakan repo untuk agent spesifik (Swift, Kotlin, Flutter, dll).

## Command Reference

Lihat file `opencode.json` untuk daftar lengkap atau jalankan `opencode` dan ketik `/` untuk melihat autocomplete.
