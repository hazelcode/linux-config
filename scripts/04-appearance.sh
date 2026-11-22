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
# 2. RESTAURACIÓN DE AJUSTES DE GNOME Y BOTONES DE VENTANA (dconf + gsettings)
# ==============================================================================
if [ -f "$REPO_DIR/dotfiles/gnome-settings.dconf" ]; then
  log_step "Restaurando configuraciones de GNOME y ventanas (dconf)..."
  dconf load -f / < "$REPO_DIR/dotfiles/gnome-settings.dconf"
  log_success "Ajustes de GNOME restaurados."
fi

if command -v gsettings >/dev/null 2>&1; then
  log_info "Aplicando tema oscuro, Material-BL y botones estilo macOS..."
  gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
  gsettings set org.gnome.desktop.interface gtk-theme 'Material-BL-LB-Dark' || true
  gsettings set org.gnome.desktop.wm.preferences theme 'Material-BL-LB-Dark' || true
  gsettings set org.gnome.desktop.wm.preferences button-layout 'close,minimize,maximize:appmenu' || true
  gsettings set org.gnome.shell.extensions.user-theme name 'Material-BL-GS-Dark' 2>/dev/null || true
fi

# ==============================================================================
# 3. FONDO DE PANTALLA PRINCIPAL (WALLPAPER)
# ==============================================================================
log_step "Configurando fondo de pantalla principal..."

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
# 4. PERSONALIZACIÓN DE GDM (STICKER /etc/gdm-logo + FONDO EN GRESOURCE)
# ==============================================================================
log_step "Configurando fondo, cursores y sticker en GDM..."

GDM_ASSETS_DIR="/usr/share/backgrounds/linux-config"
sudo mkdir -p "$GDM_ASSETS_DIR" /etc/dconf/profile /etc/dconf/db/gdm.d

# Copiar cursores a /usr/share/icons/ para el cursor de GDM
if [ -d "$REPO_DIR/icons" ]; then
  for icon_pack in "$REPO_DIR"/icons/*; do
    [ -d "$icon_pack" ] || continue
    icon_name=$(basename "$icon_pack")
    sudo rm -rf "/usr/share/icons/${icon_name}"
    sudo cp -a "$icon_pack" "/usr/share/icons/"
  done
fi

GDM_WALL_PATH=""
if [ -n "$FIRST_WALLPAPER" ]; then
  GDM_WALL_NAME="gdm-wallpaper.${FIRST_WALLPAPER##*.}"
  sudo cp -f "$FIRST_WALLPAPER" "$GDM_ASSETS_DIR/$GDM_WALL_NAME"
  sudo chmod 644 "$GDM_ASSETS_DIR/$GDM_WALL_NAME"
  GDM_WALL_PATH="$GDM_ASSETS_DIR/$GDM_WALL_NAME"
fi

GDM_LOGO_PATH=""
if [ -f "$REPO_DIR/gdm/gdm-logo" ]; then
  sudo cp -f "$REPO_DIR/gdm/gdm-logo" /etc/gdm-logo
  sudo chmod 644 /etc/gdm-logo
  GDM_LOGO_PATH="/etc/gdm-logo"
fi

# Parchear gnome-shell-theme.gresource para que GDM muestre el fondo real
ORIG_GRESOURCE="/usr/share/gnome-shell/gnome-shell-theme.gresource"
if [ -n "$GDM_WALL_PATH" ] && [ -f "$ORIG_GRESOURCE" ]; then
  if ! command -v glib-compile-resources >/dev/null 2>&1; then
    log_info "Instalando glib2-devel para compilar el tema de GDM..."
    sudo dnf install -y glib2-devel
  fi

  # Respaldar el gresource original una sola vez si no existe backup previo
  if [ ! -f "${ORIG_GRESOURCE}.orig" ]; then
    sudo cp -f "$ORIG_GRESOURCE" "${ORIG_GRESOURCE}.orig"
  fi

  WORK_DIR=$(mktemp -d)
  mkdir -p "$WORK_DIR/theme"

  # Extraer todos los recursos del tema original de GNOME Shell
  for res in $(gresource list "${ORIG_GRESOURCE}.orig"); do
    rel_path="${res#/org/gnome/shell/theme/}"
    mkdir -p "$WORK_DIR/theme/$(dirname "$rel_path")"
    gresource extract "${ORIG_GRESOURCE}.orig" "$res" > "$WORK_DIR/theme/$rel_path"
  done

  cp -f "$GDM_WALL_PATH" "$WORK_DIR/theme/$GDM_WALL_NAME"

  # Generar el manifiesto XML para glib-compile-resources
  {
    echo '<?xml version="1.0" encoding="UTF-8"?>'
    echo '<gresources>'
    echo '  <gresource prefix="/org/gnome/shell/theme">'
    (cd "$WORK_DIR/theme" && find . -type f | sed 's|^\./||' | sort | while read -r f; do
      echo "    <file>${f}</file>"
    done)
    echo '  </gresource>'
    echo '</gresources>'
  } > "$WORK_DIR/theme/gnome-shell-theme.gresource.xml"

  # Inyectar regla CSS de fondo en #lockDialogGroup dentro de gnome-shell.css
  cat << CSS >> "$WORK_DIR/theme/gnome-shell.css"

/* Custom GDM Wallpaper - linux-config */
#lockDialogGroup {
  background: #14181f url("resource:///org/gnome/shell/theme/${GDM_WALL_NAME}");
  background-size: cover;
  background-repeat: no-repeat;
  background-position: center;
}
CSS

  glib-compile-resources --sourcedir="$WORK_DIR/theme" \
    --target="$WORK_DIR/gnome-shell-theme.gresource" \
    "$WORK_DIR/theme/gnome-shell-theme.gresource.xml"

  sudo cp -f "$WORK_DIR/gnome-shell-theme.gresource" "$ORIG_GRESOURCE"
  rm -rf "$WORK_DIR"
  log_success "Tema de GDM recompilado con tu fondo de pantalla."
fi

sudo tee /etc/dconf/profile/gdm > /dev/null << 'GDMPROF'
user-db:user
system-db:gdm
file-db:/usr/share/gdm/greeter-dconf-defaults
GDMPROF

CURSOR_NAME=$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || echo "'Capitaine Cursors'")
ICON_NAME=$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || echo "'Adwaita'")

{
  echo "[org/gnome/desktop/interface]"
  echo "color-scheme='prefer-dark'"
  echo "accent-color='blue'"
  echo "cursor-theme=${CURSOR_NAME}"
  echo "icon-theme=${ICON_NAME}"
  echo "clock-format='12h'"
  echo ""
  echo "[org/gnome/login-screen]"
  if [ -n "$GDM_LOGO_PATH" ]; then
    echo "logo='${GDM_LOGO_PATH}'"
  fi
} | sudo tee /etc/dconf/db/gdm.d/96-linux-config > /dev/null

sudo dconf update
log_success "Perfil dconf de GDM actualizado."

# ==============================================================================
# 5. TEMA DE ARRANQUE GRUB2 (tachibana)
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
