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
# 1. TEMAS GTK Y GNOME SHELL (~/.themes) E ICONOS/CURSORES (~/.icons)
# ==============================================================================
log_step "Instalando temas Material-BL en \$HOME/.themes..."

THEMES_DEST="$HOME/.themes"
mkdir -p "$THEMES_DEST"

for theme in "$REPO_DIR"/themes/*; do
  [ -d "$theme" ] || continue
  theme_name=$(basename "$theme")
  rm -rf "${THEMES_DEST:?}/${theme_name}"
  cp -a "$theme" "$THEMES_DEST/"
  log_success "Tema instalado en ~/.themes: $theme_name"
done

if [ -d "$REPO_DIR/icons" ]; then
  log_step "Instalando iconos y cursores en \$HOME/.icons..."
  ICONS_DEST="$HOME/.icons"
  mkdir -p "$ICONS_DEST"

  for icon_pack in "$REPO_DIR"/icons/*; do
    [ -d "$icon_pack" ] || continue
    icon_name=$(basename "$icon_pack")
    rm -rf "${ICONS_DEST:?}/${icon_name}"
    cp -a "$icon_pack" "$ICONS_DEST/"
    log_success "Iconos/cursores instalados en ~/.icons: $icon_name"
  done
fi

# ==============================================================================
# 2. RESTAURACIÓN DE AJUSTES DE GNOME (dconf)
# ==============================================================================
if [ -f "$REPO_DIR/dotfiles/gnome-settings.dconf" ]; then
  log_step "Restaurando configuraciones de GNOME (dconf)..."
  dconf load /org/gnome/ < "$REPO_DIR/dotfiles/gnome-settings.dconf"
  log_success "Ajustes de GNOME restaurados."
fi

# ==============================================================================
# 3. FONDO DE PANTALLA (WALLPAPER)
# ==============================================================================
log_step "Configurando fondo de pantalla..."

if command -v xdg-user-dir >/dev/null 2>&1; then
  PICTURES_DIR="$(xdg-user-dir PICTURES)"
else
  PICTURES_DIR="$HOME/.local/share/backgrounds"
fi

if [ "$PICTURES_DIR" = "$HOME" ] || [ -z "$PICTURES_DIR" ]; then
  PICTURES_DIR="$HOME/.local/share/backgrounds"
fi

WALLPAPER_DEST="$PICTURES_DIR/wallpapers"
mkdir -p "$WALLPAPER_DEST"

FIRST_WALLPAPER=$(find "$REPO_DIR/wallpaper" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.webp" \) | head -n 1 || true)

if [ -n "$FIRST_WALLPAPER" ]; then
  cp -a "$REPO_DIR"/wallpaper/* "$WALLPAPER_DEST/"
  WALL_FILE="$WALLPAPER_DEST/$(basename "$FIRST_WALLPAPER")"
  gsettings set org.gnome.desktop.background picture-uri "file://$WALL_FILE" || true
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$WALL_FILE" || true
  log_success "Fondo de pantalla aplicado en $WALL_FILE"
fi

# ==============================================================================
# 4. TEMA DE ARRANQUE GRUB2 (tachibana)
# ==============================================================================
log_step "Instalando tema de GRUB2 (tachibana)..."

if [ -d "$REPO_DIR/boot/grub2/themes/tachibana" ]; then
  sudo mkdir -p /boot/grub2/themes
  sudo rm -rf /boot/grub2/themes/tachibana
  sudo cp -a "$REPO_DIR/boot/grub2/themes/tachibana" /boot/grub2/themes/

  sudo cp /etc/default/grub "/etc/default/grub.bak-$(date +%Y%m%d-%H%M%S)"

  sudo sed -i '/^GRUB_THEME=/d' /etc/default/grub
  sudo sed -i 's/^GRUB_TERMINAL_OUTPUT="console"/#GRUB_TERMINAL_OUTPUT="console"/' /etc/default/grub
  echo 'GRUB_THEME="/boot/grub2/themes/tachibana/theme.txt"' | sudo tee -a /etc/default/grub > /dev/null

  log_info "Regenerando configuración de GRUB2..."
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg
  log_success "Tema tachibana aplicado a GRUB2."
fi

log_step "Módulo 04-appearance.sh finalizado con éxito."
