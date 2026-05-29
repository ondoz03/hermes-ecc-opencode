#!/usr/bin/env bash
# ============================================================
# ECC Setup — Cross-platform (Linux / macOS / Windows Git Bash)
# One command to setup ECC + OpenCode + Hermes restore
#
# Cara pake:
#   bash ecc-setup.sh                    (interactive menu)
#   bash ecc-setup.sh 1                  (full setup)
#   bash ecc-setup.sh 2                  (opencode only)
#   bash ecc-setup.sh 3                  (hermes restore only)
#   bash ecc-setup.sh 1 gpt-4o /path    (full + custom model + path)
# ============================================================
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
MODEL="${2:-deepseek-v4-flash}"
PROJECT="${3:-.}"
REPO="https://github.com/ondoz03/hermes-ecc-opencode.git"

# Deteksi OS
OS="$(uname -s)"
case "$OS" in
  Linux*)   OS_NAME="Linux" ;;
  Darwin*)  OS_NAME="macOS" ;;
  MINGW*|MSYS*|CYGWIN*) OS_NAME="Windows (Git Bash)" ;;
  *)        OS_NAME="$OS" ;;
esac

case "$OS" in
  MINGW*|MSYS*|CYGWIN*)
    HERMES_HOME="${USERPROFILE}/.hermes"
    BACKUP_DIR="${USERPROFILE}/hermes-agent-skill"
    LOCAL_BIN="${USERPROFILE}/.local/bin"
    ;;
  *)
    HERMES_HOME="$HOME/.hermes"
    BACKUP_DIR="$HOME/hermes-agent-skill"
    LOCAL_BIN="$HOME/.local/bin"
    ;;
esac

# ============================================================
# FUNGSI-FUNGSI
# ============================================================

step() { echo -e "${YELLOW}[$1]${NC} $2"; }
ok()   { echo -e "   ${GREEN}✅${NC} $1"; }
warn() { echo -e "   ${YELLOW}⚠️${NC} $1"; }
fail() { echo -e "   ${RED}❌${NC} $1"; }

check_prerequisites() {
  step "1" "Cek prerequisites..."
  command -v node >/dev/null 2>&1 || { fail "Node.js tidak ditemukan"; echo "   Install: https://nodejs.org/"; return 1; }
  command -v npm  >/dev/null 2>&1 || { fail "npm tidak ditemukan"; return 1; }
  command -v git  >/dev/null 2>&1 || { fail "Git tidak ditemukan"; echo "   Install: https://git-scm.com/"; return 1; }
  ok "$(node -v) | npm: $(npm -v) | $(git --version | cut -d' ' -f3) | $OS_NAME"
}

install_opencode() {
  echo ""
  step "2" "OpenCode..."
  if command -v opencode &>/dev/null; then
    local ver
    ver=$(opencode --version 2>/dev/null || true)
    ok "Sudah terinstall ${ver:+($ver)}"
    return 0
  fi
  warn "Belum terinstall, menginstall..."
  case "$OS_NAME" in
    macOS*)
      if command -v brew &>/dev/null; then
        brew install opencode 2>&1 && { ok "Terinstall via brew"; return 0; } || true
      fi
      ;;
  esac
  echo "   Mencoba via script..." && curl -fsSL https://opencode.ai/install | bash 2>&1 || true
  if command -v opencode &>/dev/null; then ok "Berhasil terinstall"; return 0; fi
  echo "   Mencoba via npm..." && npm install -g opencode-ai 2>&1 || true
  if command -v opencode &>/dev/null; then ok "Berhasil terinstall"; return 0; fi
  warn "Gagal install. Manual: curl -fsSL https://opencode.ai/install | bash"
  return 1
}

install_ecc() {
  step "3" "ECC Universal..."
  if npm ls -g ecc-universal &>/dev/null; then
    ok "Sudah terinstall"
    return 0
  fi
  warn "Belum terinstall, menginstall..."
  npm install -g ecc-universal 2>&1 && { ok "ecc-universal terinstall"; return 0; } || true
  warn "Gagal install. Manual: npm install -g ecc-universal"
  return 1
}

clone_backup() {
  step "4" "Backup repo..."
  if [ -d "$BACKUP_DIR/.git" ]; then
    ok "Sudah ada di $BACKUP_DIR (pull update)"
    cd "$BACKUP_DIR" && git pull 2>/dev/null || true
  else
    git clone "$REPO" "$BACKUP_DIR"
    ok "Dicloned ke $BACKUP_DIR"
  fi
}

setup_ecc_init() {
  step "5" "Script ecc-init..."
  mkdir -p "$LOCAL_BIN"
  if [ -f "$BACKUP_DIR/local-bin/ecc-init" ]; then
    cp "$BACKUP_DIR/local-bin/ecc-init" "$LOCAL_BIN/ecc-init"
    chmod +x "$LOCAL_BIN/ecc-init"
    ok "Siap di $LOCAL_BIN/ecc-init"
  else
    warn "Tidak ditemukan di backup"
  fi
}

restore_hermes() {
  echo ""
  step "6" "Restore Hermes..."
  local count=0
  if [ -d "$BACKUP_DIR/skills" ]; then
    mkdir -p "$HERMES_HOME/skills"
    cp -r "$BACKUP_DIR/skills/"* "$HERMES_HOME/skills/" 2>/dev/null
    count=$(find "$HERMES_HOME/skills" -name 'SKILL.md' 2>/dev/null | wc -l)
    ok "$count skills"
  fi
  if [ -d "$BACKUP_DIR/memories" ]; then
    mkdir -p "$HERMES_HOME/memories"
    cp -r "$BACKUP_DIR/memories/"* "$HERMES_HOME/memories/" 2>/dev/null
    ok "Memories"
  fi
  if [ -d "$BACKUP_DIR/config" ]; then
    mkdir -p "$HERMES_HOME"
    cp "$BACKUP_DIR/config/"* "$HERMES_HOME/" 2>/dev/null || true
    ok "Config"
  fi
}

init_opencode_project() {
  echo ""
  step "7" "Init OpenCode project..."
  cd "$PROJECT"
  if command -v ecc-init &>/dev/null; then
    ecc-init -m "$MODEL"
  else
    # Manual fallback
    local ECC_PKG
    ECC_PKG=$(npm root -g 2>/dev/null)/ecc-universal
    if [ -d "$ECC_PKG" ]; then
      mkdir -p ".opencode"
      cp -r "$ECC_PKG/.opencode/"* ".opencode/" 2>/dev/null || true
      rm -f ".opencode/package.json" ".opencode/package-lock.json" ".opencode/tsconfig.json" ".opencode/MIGRATION.md" ".opencode/README.md" ".opencode/index.ts"
      rm -rf ".opencode/dist" 2>/dev/null || true
      sed -i 's/agent: everything-claude-code:/agent: /g' .opencode/commands/*.md 2>/dev/null || true
      python3 -c "import json; d=json.load(open('.opencode/opencode.json')); d['model']='$MODEL'; d['small_model']='$MODEL'; [a.pop('model',None) for a in d.get('agent',{}).values()]; d.pop('plugin',None); d['instructions']=[i for i in d.get('instructions',[]) if i.startswith('instructions/')]; json.dump(d,open('.opencode/opencode.json','w'),indent=2)" 2>/dev/null || true
    fi
    ok "ECC OpenCode ready (model: $MODEL)"
  fi
}

show_summary() {
  local count=0
  [ -d "$HERMES_HOME/skills" ] && count=$(find "$HERMES_HOME/skills" -name 'SKILL.md' 2>/dev/null | wc -l)
  echo ""
  echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║           SETUP SELESAI! 🎉           ║${NC}"
  echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "   ${CYAN}Model:${NC}      $MODEL"
  echo -e "   ${CYAN}Skills:${NC}     $count"
  echo -e "   ${CYAN}OpenCode:${NC}   $(command -v opencode &>/dev/null && echo '✅' || echo '❌')"
  echo -e "   ${CYAN}ECC:${NC}        $(npm ls -g ecc-universal &>/dev/null && echo '✅' || echo '❌')"
  echo ""
  echo -e "   ${CYAN}Next:${NC} cd $(pwd) && opencode"
  echo ""
}

# ============================================================
# MAIN
# ============================================================

echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         ECC SETUP v2.0                 ║${NC}"
echo -e "${CYAN}║         $OS_NAME${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
echo ""

# Pilihan menu
CHOICE="${1:-}"
if [ -z "$CHOICE" ]; then
  echo "Pilih setup (cek otomatis, skip kalo udah ada):"
  echo ""
  echo "  ${CYAN}1${NC}) Full     — Hermes + OpenCode + ECC"
  echo "  ${CYAN}2${NC}) OpenCode — OpenCode + ECC aja"
  echo "  ${CYAN}3${NC}) Hermes   — Restore 249 skills aja"
  echo ""
  read -r -p "Pilih [1/2/3] (default: 1): " CHOICE
  CHOICE="${CHOICE:-1}"
fi

case "$CHOICE" in
  1|2|3) ;;
  *) echo -e "${RED}Pilihan tidak valid: $CHOICE${NC}"; exit 1 ;;
esac

echo ""
echo -e "${CYAN}Mode:${NC} ${CHOICE}) $(case $CHOICE in 1) echo 'Full Setup';; 2) echo 'OpenCode Only';; 3) echo 'Hermes Only';; esac)"
echo ""

# Step 1: Prerequisites (selalu)
check_prerequisites || exit 1

# OpenCode + ECC (mode 1 & 2)
if [ "$CHOICE" = "1" ] || [ "$CHOICE" = "2" ]; then
  install_opencode || true
  install_ecc || true
  clone_backup
  setup_ecc_init
fi

# Hermes restore (mode 1 & 3)
if [ "$CHOICE" = "1" ] || [ "$CHOICE" = "3" ]; then
  if [ "$CHOICE" = "3" ]; then
    clone_backup
  fi
  restore_hermes
fi

# Init project (mode 1 & 2)
if [ "$CHOICE" = "1" ] || [ "$CHOICE" = "2" ]; then
  init_opencode_project
fi

show_summary
