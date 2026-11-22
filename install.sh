#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
  echo "Error: No ejecutes ./install.sh con sudo. El script solicitará contraseña cuando sea necesario."
  exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$REPO_DIR/scripts"

chmod +x "$SCRIPTS_DIR"/*.sh

usage() {
  cat << 'HELP'
Uso: ./install.sh [OPCIÓN]

Opciones de instalación (Sistema <- Repo):
  --all           Ejecuta toda la instalación y configuración (por defecto)
  --packages      Instala repositorios, paquetes DNF y Flatpaks
  --toolchains    Instala .NET 10.0, Rust y Roslyn LSP
  --dotfiles      Configura Zsh y copia dotfiles y ~/.config
  --appearance    Instala temas Material-BL, dconf, wallpaper y tema GRUB2

Opciones de respaldo (Sistema -> Repo):
  --sync          Copia tus configuraciones actuales del sistema hacia este repositorio
  --push          Sincroniza tus configuraciones y las sube a GitHub automáticamente
  -h, --help      Muestra esta ayuda
HELP
}

MODE="${1:---all}"

case "$MODE" in
  --all)
    "$SCRIPTS_DIR/01-packages.sh"
    "$SCRIPTS_DIR/02-toolchains.sh"
    "$SCRIPTS_DIR/03-dotfiles.sh"
    "$SCRIPTS_DIR/04-appearance.sh"
    echo -e "\n\033[1;32m[COMPLETADO]\033[0m Todo tu entorno Fedora Workstation ha sido configurado. Reinicia sesión o el equipo para aplicar todos los cambios."
    ;;
  --packages)
    "$SCRIPTS_DIR/01-packages.sh"
    ;;
  --toolchains)
    "$SCRIPTS_DIR/02-toolchains.sh"
    ;;
  --dotfiles)
    "$SCRIPTS_DIR/03-dotfiles.sh"
    ;;
  --appearance)
    "$SCRIPTS_DIR/04-appearance.sh"
    ;;
  --sync)
    "$SCRIPTS_DIR/sync.sh"
    ;;
  --push)
    "$SCRIPTS_DIR/sync.sh"
    cd "$REPO_DIR"
    if [ -n "$(git status --porcelain)" ]; then
      git add -A
      git commit -m "chore(sync): update desktop and dotfiles backup ($(date +%Y-%m-%d))"
      git push
      echo -e "\n\033[1;32m[OK]\033[0m Cambios sincronizados y subidos a GitHub."
    else
      echo -e "\n\033[1;34m[INFO]\033[0m No hay cambios nuevos que subir; el repositorio ya está al día."
    fi
    ;;
  -h|--help)
    usage
    ;;
  *)
    echo "Opción desconocida: $MODE"
    usage
    exit 1
    ;;
esac
