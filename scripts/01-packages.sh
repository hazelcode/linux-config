#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[1;34m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_step()    { echo -e "\n${CYAN}==>${NC} ${1}"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[AVISO]${NC} $1"; }

FEDORA_VER=$(rpm -E %fedora)

# ==============================================================================
# 1. REPOSITORIOS DE TERCEROS Y SOFTWARE PRIVATIVO
# ==============================================================================
log_step "Habilitando repositorios (RPM Fusion, VS Code y Ghostty COPR)..."

sudo dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_VER}.noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_VER}.noarch.rpm"

if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
  log_info "Agregando repositorio oficial de Microsoft VS Code..."
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
  sudo tee /etc/yum.repos.d/vscode.repo > /dev/null << 'REPO'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
REPO
else
  log_info "El repositorio de VS Code ya está configurado."
fi

if ! dnf repolist | grep -q "ghostty"; then
  log_info "Habilitando COPR pgdev/ghostty..."
  sudo dnf copr enable -y pgdev/ghostty
else
  log_info "Un repositorio COPR de Ghostty ya está habilitado."
fi

# ==============================================================================
# 2. PAQUETES DEL SISTEMA (DNF)
# ==============================================================================
log_step "Actualizando metadatos e instalando paquetes DNF..."

DNF_PACKAGES=(
  ghostty
  neovim
  fastfetch
  zsh
  zsh-autosuggestions
  zsh-syntax-highlighting
  util-linux-user
  gnome-tweaks
  gcc
  gcc-c++
  clang
  cmake
  ninja-build
  make
  gdb
  java-25-openjdk
  java-25-openjdk-devel
  code
)

sudo dnf upgrade --refresh -y
sudo dnf install -y --skip-unavailable "${DNF_PACKAGES[@]}"

log_success "Paquetes DNF instalados correctamente."

# ==============================================================================
# 3. APLICACIONES FLATPAK (FLATHUB)
# ==============================================================================
log_step "Configurando Flathub e instalando aplicaciones Flatpak..."

sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

FLATPAK_APPS=(
  it.mijorus.gearlever
  com.github.tchx84.Flatseal
  org.gnome.Extensions
  io.github.realmazharhussain.GdmSettings
  org.apache.netbeans
)

for app in "${FLATPAK_APPS[@]}"; do
  if flatpak list --app --columns=application | grep -qx "$app"; then
    log_info "Saltando: ${app} ya está instalado en el sistema."
  else
    log_info "Instalando Flatpak: ${app}..."
    flatpak install -y --noninteractive flathub "$app"
  fi
done

log_success "Todas las aplicaciones Flatpak han sido instaladas."
log_step "Módulo 01-packages.sh finalizado con éxito."
