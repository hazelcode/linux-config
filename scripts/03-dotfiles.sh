#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
  echo "Error: Ejecuta este script como tu usuario normal (sin sudo)."
  exit 1
fi

BLUE='\033[1;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_step()    { echo -e "\n${CYAN}==>${NC} ${1}"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[AVISO]${NC} $1"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
BACKED_UP=false

backup_if_exists() {
  local target="$1"
  # Si existe (ya sea archivo real o symlink previo), lo respaldamos antes de copiar
  if [ -e "$target" ] || [ -L "$target" ]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target" "$BACKUP_DIR/"
    BACKED_UP=true
    log_warn "Respaldo creado: $target -> $BACKUP_DIR/"
  fi
}

# ==============================================================================
# 1. CAMBIO DE SHELL PREDETERMINADA A ZSH
# ==============================================================================
log_step "Verificando shell predeterminada..."

if command -v zsh >/dev/null 2>&1; then
  CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
  ZSH_PATH=$(which zsh)
  if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    log_info "Cambiando shell predeterminada a $ZSH_PATH..."
    sudo usermod --shell "$ZSH_PATH" "$USER"
    log_success "Shell actualizada a Zsh."
  else
    log_info "Zsh ya es la shell predeterminada."
  fi
else
  log_warn "Zsh no está instalado. Ejecuta primero 01-packages.sh."
fi

# ==============================================================================
# 2. COPIA INDEPENDIENTE DE DOTFILES ($HOME)
# ==============================================================================
log_step "Instalando archivos de dotfiles en \$HOME..."

if [ -f "$REPO_DIR/dotfiles/.zshrc" ]; then
  backup_if_exists "$HOME/.zshrc"
  cp -a "$REPO_DIR/dotfiles/.zshrc" "$HOME/.zshrc"
  log_success "Copiado: ~/.zshrc"
fi

# ==============================================================================
# 3. COPIA INDEPENDIENTE DE CONFIGURACIONES ($HOME/.config)
# ==============================================================================
log_step "Instalando archivos de configuración en \$HOME/.config..."

mkdir -p "$HOME/.config"

for dir in "$REPO_DIR"/config/*; do
  [ -e "$dir" ] || continue
  name=$(basename "$dir")
  target="$HOME/.config/$name"

  backup_if_exists "$target"
  cp -a "$dir" "$target"
  log_success "Copiado: ~/.config/$name"
done

if [ "$BACKED_UP" = true ]; then
  log_warn "Tus archivos/enlaces anteriores se guardaron en: $BACKUP_DIR"
fi

log_step "Módulo 03-dotfiles.sh finalizado."
