#!/usr/bin/env bash
# ============================================================
# ECC Setup — PUBLIC (hermes-ecc-opencode)
# Simple: install OpenCode + ECC, init project
# No backup/restore — that's in the private repo version
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
MODEL="${2:-deepseek-v4-flash}"
PROJECT="${3:-.}"

OS="$(uname -s)"
case "$OS" in
  Linux*)   OS_NAME="Linux" ;;
  Darwin*)  OS_NAME="macOS" ;;
  MINGW*|MSYS*|CYGWIN*) OS_NAME="Windows (Git Bash)" ;;
  *)        OS_NAME="$OS" ;;
esac

# ============================================================
# FUNCTIONS
# ============================================================

step() { echo -e "${YELLOW}[$1]${NC} $2"; }
ok()   { echo -e "   ${GREEN}✅${NC} $1"; }
warn() { echo -e "   ${YELLOW}⚠️${NC} $1"; }
fail() { echo -e "   ${RED}❌${NC} $1"; }

check_prerequisites() {
  step "1" "Check prerequisites..."
  command -v node >/dev/null 2>&1 || { fail "Node.js not found"; echo "   Install: https://nodejs.org/"; return 1; }
  command -v npm  >/dev/null 2>&1 || { fail "npm not found"; return 1; }
  command -v git  >/dev/null 2>&1 || { fail "Git not found"; echo "   Install: https://git-scm.com/"; return 1; }
  ok "$(node -v) | npm: $(npm -v) | $(git --version | cut -d' ' -f3) | $OS_NAME"
}

install_opencode() {
  echo ""
  step "2" "OpenCode..."
  if command -v opencode &>/dev/null; then
    local ver; ver=$(opencode --version 2>/dev/null || true)
    ok "Already installed ${ver:+($ver)}"
    return 0
  fi
  warn "Not found, installing..."
  case "$OS_NAME" in
    macOS*)
      if command -v brew &>/dev/null; then
        brew install opencode 2>&1 && { ok "Installed via brew"; return 0; } || true
      fi
      ;;
  esac
  echo "   Trying script..." && curl -fsSL https://opencode.ai/install | bash 2>&1 || true
  if command -v opencode &>/dev/null; then ok "Installed successfully"; return 0; fi
  echo "   Trying npm..." && npm install -g opencode-ai 2>&1 || true
  if command -v opencode &>/dev/null; then ok "Installed successfully"; return 0; fi
  warn "Install failed. Manual: curl -fsSL https://opencode.ai/install | bash"
  return 1
}

install_ecc() {
  step "3" "ECC Universal..."
  if npm ls -g ecc-universal &>/dev/null; then
    ok "Already installed"
    return 0
  fi
  warn "Not found, installing..."
  npm install -g ecc-universal 2>&1 && { ok "ecc-universal installed"; return 0; } || true
  warn "Install failed. Manual: npm install -g ecc-universal"
  return 1
}

init_opencode_project() {
  echo ""
  step "4" "Init OpenCode project..."
  cd "$PROJECT"
  local ECC_PKG; ECC_PKG=$(npm root -g 2>/dev/null)/ecc-universal
  if [ -d "$ECC_PKG" ]; then
    mkdir -p ".opencode"
    cp -r "$ECC_PKG/.opencode/"* ".opencode/" 2>/dev/null || true
    rm -f ".opencode/package.json" ".opencode/package-lock.json" ".opencode/tsconfig.json" \
          ".opencode/MIGRATION.md" ".opencode/README.md" ".opencode/index.ts"
    rm -rf ".opencode/dist" 2>/dev/null || true
    sed -i 's/agent: everything-claude-code:/agent: /g' .opencode/commands/*.md 2>/dev/null || true
    python3 -c "
import json
path = '.opencode/opencode.json'
d = json.load(open(path))
d['model'] = '$MODEL'
d['small_model'] = '$MODEL'
for name, agent in d.get('agent', {}).items():
    agent.pop('model', None)
d.pop('plugin', None)
d['instructions'] = [i for i in d.get('instructions', []) if i.startswith('instructions/')]
json.dump(d, open(path, 'w'), indent=2)
" 2>/dev/null || true
    ok "ECC OpenCode ready (model: $MODEL)"
  else
    warn "ecc-universal not found — can't init project"
  fi
}

show_summary() {
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║         SETUP COMPLETE! 🎉             ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "   ${CYAN}Model:${NC}    $MODEL"
  echo -e "   ${CYAN}OpenCode:${NC} $(command -v opencode &>/dev/null && echo '✅' || echo '❌')"
  echo -e "   ${CYAN}ECC:${NC}      $(npm ls -g ecc-universal &>/dev/null && echo '✅' || echo '❌')"
  echo ""
  echo -e "   ${CYAN}Next:${NC} opencode"
  echo ""
}

# ============================================================
# MAIN
# ============================================================

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ECC SETUP — PUBLIC             ║${NC}"
echo -e "${CYAN}║         $OS_NAME${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

check_prerequisites || exit 1
install_opencode || true
install_ecc || true
init_opencode_project
show_summary
