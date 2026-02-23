#!/bin/bash

# Termux Dev Stack - Installer
# Author: Manus AI (based on user documentation)
# Date: 2026-02-23

set -e

echo "🚀 Iniciando instalação do Termux Dev Stack..."

# 1. SETUP INICIAL
echo "📦 Atualizando pacotes e instalando ferramentas base..."
pkg update && pkg upgrade -y
pkg install -y \
    git \
    nodejs-lts \
    npm \
    python3 \
    build-essential \
    curl \
    wget \
    vim \
    nano \
    zsh \
    openssh \
    sqlite \
    proot-distro \
    rsync

# 2. DIRETÓRIOS
echo "📁 Criando estrutura de diretórios..."
mkdir -p ~/.termux/scripts
mkdir -p ~/.termux/hub/{wrappers,sync,cache,docs}
mkdir -p ~/.config/llm/aliases
mkdir -p ~/.aihub/{config,data,logs,scripts}
mkdir -p ~/projects

# 3. ZSH + OH-MY-ZSH
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🐚 Instalando Oh-My-Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Plugins e Temas
echo "🎨 Instalando Powerlevel10k e plugins Zsh..."
[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ] || \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ] || \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ] || \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 4. CONFIGURAÇÃO HUB MCP (SQLite)
echo "🗄️ Configurando Hub MCP..."
cat > ~/.termux/hub/init-db.sql << 'SQL_EOF'
CREATE TABLE IF NOT EXISTS skills (
    id INTEGER PRIMARY KEY,
    name TEXT UNIQUE,
    category TEXT,
    description TEXT,
    examples TEXT,
    usage TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT OR IGNORE INTO skills (name, category, description, examples, usage) VALUES
('git clone', 'git', 'Clone um repositório', 'git clone https://github.com/user/repo', 'git clone <url>'),
('npm install', 'npm', 'Instalar dependências', 'npm install / npm i', 'npm install [package]'),
('npm run dev', 'npm', 'Iniciar dev server', 'npm run dev', 'npm run dev'),
('git push', 'git', 'Enviar commits', 'git push origin main', 'git push [remote] [branch]'),
('git pull', 'git', 'Baixar atualizações', 'git pull origin main', 'git pull [remote] [branch]'),
('docker run', 'docker', 'Executar container', 'docker run -it ubuntu bash', 'docker run [options] image'),
('find', 'system', 'Procurar arquivos', 'find . -name "*.js"', 'find [path] -name [pattern]'),
('grep', 'system', 'Buscar em arquivos', 'grep -r "pattern" .', 'grep [options] pattern [files]'),
('curl', 'network', 'Fazer requisições HTTP', 'curl -X POST http://api.example.com', 'curl [url]');

CREATE TABLE IF NOT EXISTS aliases (
    id INTEGER PRIMARY KEY,
    alias TEXT UNIQUE,
    command TEXT,
    description TEXT
);

INSERT OR IGNORE INTO aliases (alias, command, description) VALUES
('pj', 'cd ~/projects', 'Ir para pasta de projetos'),
('dev', 'npm run dev', 'Iniciar dev server'),
('gs', 'git status', 'Ver status do git'),
('gp', 'git push', 'Enviar commits'),
('gl', 'git pull', 'Receber updates'),
('gc', 'git commit -m', 'Fazer commit'),
('startx11', 'termux-x11 :0 -xstartup "dbus-launch --exit-with-session xfce4-session"', 'Iniciar desktop X11');
SQL_EOF

sqlite3 ~/.termux/hub/database.db < ~/.termux/hub/init-db.sql

# 5. SCRIPTS E ALIASES
echo "📜 Instalando scripts de suporte..."

# Hub Script
cat > ~/.termux/hub/hub.sh << 'HUB_EOF'
#!/bin/bash
HUB_DB="$HOME/.termux/hub/database.db"
hub() {
    local action="$1"
    local query="$2"
    case "$action" in
        ask) sqlite3 "$HUB_DB" "SELECT description, usage, examples FROM skills WHERE name LIKE '%$query%' LIMIT 1" ;;
        search) sqlite3 "$HUB_DB" "SELECT name, description FROM skills WHERE category='$query' OR description LIKE '%$query%'" ;;
        list) sqlite3 "$HUB_DB" "SELECT DISTINCT category FROM skills" ;;
        add) sqlite3 "$HUB_DB" "INSERT INTO skills (name, category, description) VALUES ('$2', '$3', '$4')" ; echo "✓ Skill '$2' adicionado!" ;;
        *) echo "Uso: hub [ask|search|list|add]" ;;
    esac
}
hub "$@"
HUB_EOF
chmod +x ~/.termux/hub/hub.sh

# Sync Script
cat > ~/.termux/hub/sync/termux-sync.sh << 'SYNC_EOF'
#!/bin/bash
echo "=== Sincronizando Termux ↔ Ubuntu ==="
TERMUX_HOME="$HOME"
UBUNTU_HOME="/data/data/com.termux/files/home/ubuntu/root"
mkdir -p "$UBUNTU_HOME/projects" "$UBUNTU_HOME/.config" "$UBUNTU_HOME/.ssh"
ln -sf "$TERMUX_HOME/projects" "$UBUNTU_HOME/projects" 2>/dev/null
ln -sf "$TERMUX_HOME/.config" "$UBUNTU_HOME/.config" 2>/dev/null
ln -sf "$TERMUX_HOME/.ssh" "$UBUNTU_HOME/.ssh" 2>/dev/null
echo "✓ Sincronização completa!"
SYNC_EOF
chmod +x ~/.termux/hub/sync/termux-sync.sh

# 6. CONFIGURAÇÃO .ZSHRC
echo "⚙️ Configurando .zshrc..."
cat > ~/.zshrc << 'ZSHRC_EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git command-not-found colored-man-pages extract zsh-autosuggestions zsh-syntax-highlighting)
source $ZSH/oh-my-zsh.sh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Aliases
alias ls='ls -lah --color=auto'
alias pj='cd ~/projects'
alias dev='npm run dev'
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias gc='git commit -m'
alias ga='git add'
alias c='clear'
alias hub='~/.termux/hub/hub.sh'
alias ubuntu='proot-distro login ubuntu'

# Functions
next-project() {
    npx create-next-app@latest "${1:-my-app}" --typescript --tailwind --app --eslint
}

echo "🚀 Termux Dev Environment Ready!"
ZSHRC_EOF

# 7. CODE-SERVER
echo "💻 Instalando Code-Server..."
npm install -g code-server || echo "Aviso: Falha ao instalar code-server globalmente."

echo "✅ Instalação concluída!"
echo "Reinicie o Termux ou execute: source ~/.zshrc"
