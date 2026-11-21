# linux-config

Mis configuraciones opinadas personales de Linux, elegidas para desarrolladores como yo. Todo lo que se instala y configura aquí tiene opinión propia, conforme a mis gustos personales y mi stack de desarrollo de software.

## Preferencias personales

**Temáticas:** Anime (Ado, temas de anime)

**Stack de desarrollo:** Java, .NET C#, C/C++, Rust

**IDEs y editores de código:** VSCode, Apache NetBeans, Neovim (Lazyvim)

**Gustos de colores**: Tonos azules, grises y negros.

**Terminal y shell:** Ghostty con Zsh

## Especificaciones

**Distro recomendada:** Fedora Workstation 45

**Shell:** GNOME 45

**Versión de GTK:** GTK 4

**Shell de preferencia:** Zsh

## Programas o componentes a instalar

**Advertencia: Por preferencias personales se instalarán herramientas de desarrollo como .NET, Rust y C/C++, así como editores de código e IDEs como Apache NetBeans y VSCode**

*El repositorio instala los siguientes programas o componentes:*

### Instalaciones manuales (automatizadas)

- Una instalación manual de .NET 10.0 (Via script)
- Una instalación manual de Rust (Via script)

### Flatpak
- Gearlever
- Flatseal
- GNOME Tweaks
- GNOME Extensions
- GDM Settings
- Apache NetBeans

### DNF
- *Habilita repositorio de software privativo*
- **No instala Ghostty, Neovim ni Fastfetch automáticamente (Por ahora)**
- Zsh
- Make
- CMake
- GCC
- Clang
- OpenJDK 25
- Vscode *(Intencionalmente como paquete de sistema, no como Flatpak debido al sandbox)*

*Este repositorio provee configuraciones para los siguientes programas o paquetes, pero no se limita a:*

- ghostty
- neovim
- fastfetch
- grub2
- gtk4

El repositorio configura una instalación manual de **Dotnet** y el servidor LSP de **Roslyn** listos para Lazyvim, así como la **variable de entorno $PATH**
