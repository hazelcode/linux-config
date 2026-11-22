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

# ==============================================================================
# 1. SINCRONIZAR DOTFILES Y AJUSTES DE GNOME (dconf)
# ==============================================================================
log_step "Sincronizando dotfiles y dconf hacia el repositorio..."

if [ -f "$HOME/.zshrc" ]; then
  cp -a "$HOME/.zshrc" "$REPO_DIR/dotfiles/.zshrc"
  log_success "Actualizado: dotfiles/.zshrc"
fi

if command -v dconf >/dev/null 2>&1; then
  dconf dump /org/gnome/ > "$REPO_DIR/dotfiles/gnome-settings.dconf"
  log_success "Actualizado: dotfiles/gnome-settings.dconf"
fi

# ==============================================================================
# 2. SINCRONIZAR DIRECTORIOS DE CONFIGURACIÓN (~/.config -> config/)
# ==============================================================================
log_step "Sincronizando configuraciones de ~/.config..."

CONFIG_DIRS=(
  ghostty
  nvim
  fastfetch
  gtk-4.0
)

for dir in "${CONFIG_DIRS[@]}"; do
  if [ -d "$HOME/.config/$dir" ]; then
    rm -rf "${REPO_DIR:?}/config/${dir}"
    cp -a "$HOME/.config/$dir" "$REPO_DIR/config/"
    # Evitar submódulos .git accidentales dentro de config/
    rm -rf "$REPO_DIR/config/$dir/.git"
    log_success "Actualizado: config/$dir"
  else
    log_warn "No se encontró ~/.config/$dir en el sistema; se omite."
  fi
done

# ==============================================================================
# 3. SINCRONIZAR TEMAS (~/.themes) E ICONOS (~/.icons)
# ==============================================================================
log_step "Sincronizando temas instalados..."

for theme in "$REPO_DIR"/themes/*; do
  [ -d "$theme" ] || continue
  theme_name=$(basename "$theme")
  if [ -d "$HOME/.themes/$theme_name" ]; then
    rm -rf "${REPO_DIR:?}/themes/${theme_name}"
    cp -a "$HOME/.themes/$theme_name" "$REPO_DIR/themes/"
    log_success "Actualizado: themes/$theme_name"
  fi
done

if [ -d "$REPO_DIR/icons" ] && [ -d "$HOME/.icons" ]; then
  for icon_pack in "$REPO_DIR"/icons/*; do
    [ -d "$icon_pack" ] || continue
    icon_name=$(basename "$icon_pack")
    if [ -d "$HOME/.icons/$icon_name" ]; then
      rm -rf "${REPO_DIR:?}/icons/${icon_name}"
      cp -a "$HOME/.icons/$icon_name" "$REPO_DIR/icons/"
      log_success "Actualizado: icons/$icon_name"
    fi
  done
fi

# ==============================================================================
# 4. SINCRONIZAR WALLPAPER ACTUAL DE GNOME
# ==============================================================================
if command -v gsettings >/dev/null 2>&1; then
  CURRENT_WALL=$(gsettings get org.gnome.desktop.background picture-uri-dark | tr -d "'" | sed 's|^file://||')
  if [ -f "$CURRENT_WALL" ]; then
    WALL_BASENAME=$(basename "$CURRENT_WALL")
    if [ ! -f "$REPO_DIR/wallpaper/$WALL_BASENAME" ]; then
      rm -rf "${REPO_DIR:?}/wallpaper"/*
      cp -a "$CURRENT_WALL" "$REPO_DIR/wallpaper/"
      log_success "Nuevo fondo de pantalla respaldado: wallpaper/$WALL_BASENAME"
    else
      log_info "El fondo de pantalla en wallpaper/ ya coincide con el actual."
    fi
  fi
fi

log_step "Sincronización completada. Revisa los cambios con 'git status' y 'git diff'."
