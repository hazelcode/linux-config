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
# 1. SINCRONIZAR DOTFILES Y AJUSTES DE GNOME / MUTTER (dconf filtrado)
# ==============================================================================
log_step "Sincronizando dotfiles y dconf hacia el repositorio..."

if [ -f "$HOME/.zshrc" ]; then
  cp -a "$HOME/.zshrc" "$REPO_DIR/dotfiles/.zshrc"
  log_success "Actualizado: dotfiles/.zshrc"
fi

if command -v dconf >/dev/null 2>&1; then
  DCONF_FILE="$REPO_DIR/dotfiles/gnome-settings.dconf"
  : > "$DCONF_FILE"

  DCONF_PATHS=(
    "/org/gnome/desktop/interface/"
    "/org/gnome/desktop/wm/preferences/"
    "/org/gnome/desktop/wm/keybindings/"
    "/org/gnome/desktop/peripherals/"
    "/org/gnome/mutter/"
    "/org/gnome/shell/extensions/"
    "/org/gnome/settings-daemon/plugins/media-keys/"
  )

  for path in "${DCONF_PATHS[@]}"; do
    section="${path#/}"
    section="${section%/}"
    dump_content=$(dconf dump "$path")
    if [ -n "$dump_content" ]; then
      echo "$dump_content" | sed -E -e "s|^\[/\]$|[${section}]|" -e "s|^\[(.*)\]$|[${section}/\1]|" >> "$DCONF_FILE"
      echo "" >> "$DCONF_FILE"
    fi
  done

  ENABLED_EXTS=$(dconf read /org/gnome/shell/enabled-extensions || true)
  if [ -n "$ENABLED_EXTS" ]; then
    printf "[org/gnome/shell]\nenabled-extensions=%s\n" "$ENABLED_EXTS" >> "$DCONF_FILE"
  fi

  log_success "Actualizado (filtrado y escribible): dotfiles/gnome-settings.dconf"
fi

# ==============================================================================
# 2. SINCRONIZAR DIRECTORIOS DE CONFIGURACIÓN (~/.config -> config/)
# ==============================================================================
log_step "Sincronizando configuraciones de ~/.config..."

CONFIG_DIRS=(
  ghostty
  nvim
  fastfetch
  gtk-3.0
  gtk-4.0
)

for dir in "${CONFIG_DIRS[@]}"; do
  if [ -d "$HOME/.config/$dir" ]; then
    rm -rf "${REPO_DIR:?}/config/${dir}"
    cp -a "$HOME/.config/$dir" "$REPO_DIR/config/"
    rm -rf "$REPO_DIR/config/$dir/.git"
    log_success "Actualizado: config/$dir"
  else
    log_warn "No se encontró ~/.config/$dir en el sistema; se omite."
  fi
done

# ==============================================================================
# 3. SINCRONIZAR TEMAS (~/.themes) E ICONOS/CURSORES (~/.icons)
# ==============================================================================
log_step "Sincronizando temas, iconos y cursores instalados..."

for theme in "$REPO_DIR"/themes/*; do
  [ -d "$theme" ] || continue
  theme_name=$(basename "$theme")
  if [ -d "$HOME/.themes/$theme_name" ]; then
    rm -rf "${REPO_DIR:?}/themes/${theme_name}"
    cp -a "$HOME/.themes/$theme_name" "$REPO_DIR/themes/"
    log_success "Actualizado: themes/$theme_name"
  fi
done

if [ -d "$HOME/.icons" ]; then
  mkdir -p "$REPO_DIR/icons"
  for icon_pack in "$HOME/.icons"/*; do
    [ -d "$icon_pack" ] || continue
    icon_name=$(basename "$icon_pack")
    rm -rf "${REPO_DIR:?}/icons/${icon_name}"
    cp -a "$icon_pack" "$REPO_DIR/icons/"
    log_success "Respaldado en icons/: $icon_name"
  done
fi

# ==============================================================================
# 4. SINCRONIZAR WALLPAPER ACTUAL DE GNOME Y STICKER DE GDM (/etc/gdm-logo)
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

if [ -f "/etc/gdm-logo" ]; then
  mkdir -p "$REPO_DIR/gdm"
  cp -f /etc/gdm-logo "$REPO_DIR/gdm/gdm-logo"
  log_success "Respaldado sticker de GDM: gdm/gdm-logo"
fi

log_step "Sincronización completada. Revisa los cambios con 'git status' y 'git diff'."
