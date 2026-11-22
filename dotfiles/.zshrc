# ==========================================
# VARIABLES DE ENTORNO Y PATH
# ==========================================
export DOTNET_ROOT="$HOME/.dotnet"
export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
export EDITOR="nvim"
export VISUAL="nvim"

# Evita rutas duplicadas en $PATH
typeset -U path
path=(
  "$HOME/.local/bin"
  "$DOTNET_ROOT"
  "$DOTNET_ROOT/tools"
  "$CARGO_HOME/bin"
  $path
)
export PATH

# ==========================================
# HISTORIAL Y COMPORTAMIENTO DE ZSH
# ==========================================
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt AUTO_CD

# Autocompletado nativo insensible a mayúsculas/minúsculas
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' menu select

# ==========================================
# PROMPT (Paleta azul / cian / gris)
# ==========================================
setopt PROMPT_SUBST
PROMPT='%F{39}[%n@%m]%f %F{248}%~%f %F{45}%#%f '

# ==========================================
# ALIASES
# ==========================================
alias ls='ls --color=auto'
alias ll='ls -lh --color=auto'
alias la='ls -lha --color=auto'
alias grep='grep --color=auto'
alias nv='nvim'
alias ff='fastfetch'
alias gs='git status'
alias gp='git pull'
alias gc='git commit -m'

# ==========================================
# PLUGINS
# ==========================================
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
