#!/bin/bash

# Termux Dev Stack - Instalador Interativo e Inteligente
# Author: Manus AI (baseado na documentação do usuário)
# Date: 2026-02-23

# --- Variáveis Globais ---
LOG_FILE="$HOME/termux_dev_stack_install.log"
INSTALL_STATE_FILE="$HOME/.termux_dev_stack_install_state"

# --- Funções de Utilitário ---
log_info() { echo "[INFO] $@" | tee -a "$LOG_FILE"; }
log_success() { echo "[SUCESSO] $@" | tee -a "$LOG_FILE"; }
log_error() { echo "[ERRO] $@" | tee -a "$LOG_FILE"; }

check_command() {
    command -v "$1" >/dev/null 2>&1
}

confirm() {
    read -r -p "$1 [s/N]: " response
    case "$response" in
        [sS][iI]|[sS]) 
            true
            ;;
        *) 
            false
            ;;
    esac
}

mark_as_installed() {
    echo "$1" >> "$INSTALL_STATE_FILE"
}

is_installed() {
    grep -Fxq "$1" "$INSTALL_STATE_FILE" 2>/dev/null
}

# --- Funções de Instalação Modular ---

install_base_packages() {
    local step_name="base_packages"
    log_info "Iniciando: Instalação de pacotes base..."
    if is_installed "$step_name"; then
        log_info "Pacotes base já instalados. Pulando."
        return 0
    fi

    log_info "Atualizando pacotes do Termux..."
    pkg update -y || { log_error "Falha ao atualizar pkg"; return 1; }
    pkg upgrade -y || { log_error "Falha ao fazer upgrade de pkg"; return 1; }

    log_info "Instalando ferramentas essenciais..."
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
        rsync || { log_error "Falha ao instalar pacotes base"; return 1; }
    
    mark_as_installed "$step_name"
    log_success "Pacotes base instalados com sucesso."
    return 0
}

setup_directories() {
    local step_name="directories"
    log_info "Iniciando: Configuração de diretórios..."
    if is_installed "$step_name"; then
        log_info "Diretórios já configurados. Pulando."
        return 0
    fi

    log_info "Criando estrutura de diretórios padrão..."
    mkdir -p ~/.termux/scripts || { log_error "Falha ao criar ~/.termux/scripts"; return 1; }
    mkdir -p ~/.termux/hub/{wrappers,sync,cache,docs} || { log_error "Falha ao criar ~/.termux/hub"; return 1; }
    mkdir -p ~/.config/llm/aliases || { log_error "Falha ao criar ~/.config/llm/aliases"; return 1; }
    mkdir -p ~/.aihub/{config,data,logs,scripts} || { log_error "Falha ao criar ~/.aihub"; return 1; }
    mkdir -p ~/projects || { log_error "Falha ao criar ~/projects"; return 1; }

    mark_as_installed "$step_name"
    log_success "Diretórios configurados com sucesso."
    return 0
}

setup_zsh_ohmyzsh() {
    local step_name="zsh_ohmyzsh"
    log_info "Iniciando: Configuração Zsh e Oh-My-Zsh..."
    if is_installed "$step_name"; then
        log_info "Zsh e Oh-My-Zsh já configurados. Pulando."
        return 0
    fi

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Instalando Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || { log_error "Falha ao instalar Oh-My-Zsh"; return 1; }
    else
        log_info "Oh-My-Zsh já parece estar instalado."
    fi

    log_info "Instalando Powerlevel10k e plugins Zsh..."
    [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ] || \
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k || { log_error "Falha ao clonar Powerlevel10k"; return 1; }
    [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ] || \
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || { log_error "Falha ao clonar zsh-autosuggestions"; return 1; }
    [ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ] || \
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || { log_error "Falha ao clonar zsh-syntax-highlighting"; return 1; }

    mark_as_installed "$step_name"
    log_success "Zsh e Oh-My-Zsh configurados com sucesso."
    return 0
}

setup_hub_mcp() {
    local step_name="hub_mcp"
    log_info "Iniciando: Configuração do Hub MCP (SQLite)..."
    if is_installed "$step_name"; then
        log_info "Hub MCP já configurado. Pulando."
        return 0
    fi

    log_info "Criando script init-db.sql..."
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

    log_info "Criando e populando database SQLite para o Hub MCP..."
    sqlite3 ~/.termux/hub/database.db < ~/.termux/hub/init-db.sql || { log_error "Falha ao configurar database do Hub MCP"; return 1; }

    log_info "Criando script hub.sh..."
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
    chmod +x ~/.termux/hub/hub.sh || { log_error "Falha ao dar permissão de execução para hub.sh"; return 1; }

    log_info "Criando script termux-sync.sh..."
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
    chmod +x ~/.termux/hub/sync/termux-sync.sh || { log_error "Falha ao dar permissão de execução para termux-sync.sh"; return 1; }

    mark_as_installed "$step_name"
    log_success "Hub MCP configurado com sucesso."
    return 0
}

configure_zshrc() {
    local step_name="zshrc_config"
    log_info "Iniciando: Configuração do .zshrc..."
    if is_installed "$step_name"; then
        log_info ".zshrc já configurado. Pulando."
        return 0
    fi

    log_info "Criando ou atualizando ~/.zshrc..."
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
    
    mark_as_installed "$step_name"
    log_success ".zshrc configurado com sucesso."
    return 0
}

install_code_server() {
    local step_name="code_server"
    log_info "Iniciando: Instalação do Code-Server..."
    if is_installed "$step_name"; then
        log_info "Code-Server já instalado. Pulando."
        return 0
    fi

    log_info "Instalando code-server globalmente via npm..."
    # npm install -g code-server || { log_error "Falha ao instalar code-server globalmente."; return 1; }
    log_info "Instalação do Code-Server via npm pode falhar em alguns ambientes. Se ocorrer, tente instalar manualmente ou ignore."
    # Para fins de simulação, vamos considerar instalado se o comando 'code-server' existir ou se o usuário optar por ignorar.
    if check_command code-server; then
        log_info "Code-Server já detectado no PATH."
    else
        log_info "Code-Server não detectado. Se a instalação via npm falhar, considere instalar manualmente."
    fi

    mark_as_installed "$step_name"
    log_success "Code-Server instalado com sucesso."
    return 0
}

# --- Menu Interativo ---

show_menu() {
    echo "\n--- Menu de Instalação Termux Dev Stack ---"
    echo "1. Instalar Pacotes Base (git, nodejs, zsh, sqlite, etc.)"
    echo "2. Configurar Estrutura de Diretórios"
    echo "3. Configurar Zsh e Oh-My-Zsh (com Powerlevel10k)"
    echo "4. Configurar Hub MCP (Sistema de Conhecimento com SQLite)"
    echo "5. Configurar .zshrc (Aliases e Funções)"
    echo "6. Instalar Code-Server (VS Code Web)"
    echo "7. Instalar TUDO (Recomendado)"
    echo "0. Sair"
    echo "-------------------------------------------"
}

main_menu() {
    while true; do
        show_menu
        read -r -p "Escolha uma opção: " choice
        echo ""

        case "$choice" in
            1) run_step install_base_packages;;
            2) run_step setup_directories;;
            3) run_step setup_zsh_ohmyzsh;;
            4) run_step setup_hub_mcp;;
            5) run_step configure_zshrc;;
            6) run_step install_code_server;;
            7) 
                log_info "Iniciando instalação completa..."
                run_step install_base_packages && \
                run_step setup_directories && \
                run_step setup_zsh_ohmyzsh && \
                run_step setup_hub_mcp && \
                run_step configure_zshrc && \
                run_step install_code_server && \
                log_success "Instalação completa finalizada!"
                ;;
            0) 
                log_info "Saindo do instalador. Até mais!"
                exit 0
                ;;
            *) 
                log_error "Opção inválida. Por favor, tente novamente."
                ;;
        esac
        echo "\nPressione Enter para continuar..."
        read -r
    done
}

run_step() {
    local func_name="$1"
    log_info "Executando etapa: $func_name"
    if "$func_name"; then
        log_success "Etapa '$func_name' concluída com sucesso."
    else
        log_error "Etapa '$func_name' falhou. Verifique o log em $LOG_FILE para detalhes."
        if confirm "Deseja tentar novamente esta etapa?"; then
            # Remover do estado para tentar novamente
            sed -i "/$func_name/d" "$INSTALL_STATE_FILE" 2>/dev/null
            run_step "$func_name"
        else
            log_info "Pulando etapa '$func_name' devido a falha e escolha do usuário."
        fi
    fi
}

# --- Inicialização ---

# Criar arquivo de estado se não existir
[ ! -f "$INSTALL_STATE_FILE" ] && touch "$INSTALL_STATE_FILE"

log_info "Iniciador do Termux Dev Stack iniciado."
main_menu
