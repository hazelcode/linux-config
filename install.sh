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

Opciones:
  --all           Ejecuta toda la instalación y configuración (por defecto)
  --packages      Instala repositorios, paquetes DNF y Flatpaks
  --toolchains    Instala .NET 10.0, Rust y Roslyn LSP
  --dotfiles      Configura Zsh y copia dotfiles y ~/.config
  --appearance    Instala temas Material-BL, dconf, wallpaper y tema GRUB2
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
  -h|--help)
    usage
    ;;
  *)
    echo "Opción desconocida: $MODE"
    usage
    exit 1
    ;;
esac
