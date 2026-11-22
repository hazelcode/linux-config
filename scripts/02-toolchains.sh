#!/usr/bin/env bash
set -euo pipefail

if [ "$EUID" -eq 0 ]; then
  echo "Error: Ejecuta este script como tu usuario normal (sin sudo) para instalar .NET y Rust en tu \$HOME."
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

# ==============================================================================
# 1. INSTALACIÓN MANUAL DE .NET 10.0
# ==============================================================================
log_step "Instalando .NET SDK 10.0 en \$HOME/.dotnet..."

DOTNET_INSTALL_DIR="$HOME/.dotnet"
mkdir -p "$DOTNET_INSTALL_DIR"

curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
chmod +x /tmp/dotnet-install.sh
/tmp/dotnet-install.sh --channel 10.0 --install-dir "$DOTNET_INSTALL_DIR"
rm -f /tmp/dotnet-install.sh

export DOTNET_ROOT="$DOTNET_INSTALL_DIR"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

log_success ".NET instalado: $(dotnet --version)"

# ==============================================================================
# 2. INSTALACIÓN MANUAL DE RUST (RUSTUP)
# ==============================================================================
log_step "Instalando toolchain de Rust mediante rustup..."

if [ ! -x "$HOME/.cargo/bin/rustc" ]; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
else
  log_info "Rustup ya está instalado. Actualizando toolchains..."
  "$HOME/.cargo/bin/rustup" update
fi

export CARGO_HOME="$HOME/.cargo"
export PATH="$CARGO_HOME/bin:$PATH"

log_success "Rust instalado: $(rustc --version)"

# ==============================================================================
# 3. SERVIDOR LSP DE ROSLYN PARA LAZYVIM (NEOVIM)
# ==============================================================================
log_step "Configurando servidor LSP de Roslyn desde NuGet oficial..."

ROSLYN_DIR="$HOME/.local/share/roslyn-lsp"
PKG_ID="microsoft.codeanalysis.languageserver.linux-x64"
mkdir -p "$ROSLYN_DIR" "$HOME/.local/bin"

log_info "Consultando última versión de Microsoft.CodeAnalysis.LanguageServer.linux-x64..."
ROSLYN_VER=$(curl -fsSL "https://api.nuget.org/v3-flatcontainer/${PKG_ID}/index.json" \
  | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+(-[^"]+)?"' \
  | grep -v -- '-' \
  | tail -n 1 \
  | tr -d '"' || true)

# Si no hay versión sin guion (solo pre-releases), tomar la última disponible
if [ -z "$ROSLYN_VER" ]; then
  ROSLYN_VER=$(curl -fsSL "https://api.nuget.org/v3-flatcontainer/${PKG_ID}/index.json" \
    | grep -oE '"[0-9]+\.[0-9]+\.[0-9]+[^"]*"' \
    | tail -n 1 \
    | tr -d '"' || true)
fi

if [ -n "$ROSLYN_VER" ]; then
  log_info "Descargando Roslyn LSP v${ROSLYN_VER}..."
  NUPKG_URL="https://api.nuget.org/v3-flatcontainer/${PKG_ID}/${ROSLYN_VER}/${PKG_ID}.${ROSLYN_VER}.nupkg"
  curl -fsSL "$NUPKG_URL" -o /tmp/roslyn-lsp.nupkg

  rm -rf "${ROSLYN_DIR:?}"/*
  unzip -q /tmp/roslyn-lsp.nupkg "content/LanguageServer/linux-x64/*" -d /tmp/roslyn-extract
  mv /tmp/roslyn-extract/content/LanguageServer/linux-x64/* "$ROSLYN_DIR/"
  rm -rf /tmp/roslyn-lsp.nupkg /tmp/roslyn-extract

  # Crear wrapper ejecutable en ~/.local/bin/roslyn
  cat << 'WRAPPER' > "$HOME/.local/bin/roslyn"
#!/usr/bin/env bash
exec "$HOME/.dotnet/dotnet" "$HOME/.local/share/roslyn-lsp/Microsoft.CodeAnalysis.LanguageServer.dll" "$@"
WRAPPER
  chmod +x "$HOME/.local/bin/roslyn"

  log_success "Roslyn LSP v${ROSLYN_VER} instalado y listo en ~/.local/bin/roslyn"
else
  log_warn "No se pudo consultar la versión en NuGet. Verifica tu conexión a internet."
fi

log_step "Módulo 02-toolchains.sh finalizado con éxito."
