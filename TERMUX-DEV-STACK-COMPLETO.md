# 🚀 DOCUMENTAÇÃO COMPLETA: Dev Stack Termux Samsung Galaxy S24 Ultra

**Arquivo único com TUDO: scripts, setup, configurações, troubleshooting**

**Atualização:** Fevereiro 23, 2026 | Termux 2025.01.18+ | Node.js 20+ LTS | One UI 8.0+

---

## 📋 ÍNDICE RÁPIDO

```
1. SETUP INICIAL (10 min)
2. HUB MCP CENTRALIZADO (15 min)
3. DUAL-SHELL TERMUX ↔ UBUNTU (20 min)
4. CLI LLMS UNIFICADO (10 min)
5. DEV WEBAPP NEXT.JS + SUPABASE (15 min)
6. CODE-SERVER (VS CODE WEB) (10 min)
7. ALIASES E WORKFLOW (5 min)
8. AI HUB CENTRALIZADO (20 min)
9. TROUBLESHOOTING & DICAS (referência)

⏱️ TEMPO TOTAL: ~2 horas pra setup completo
```

---

---

## 1. SETUP INICIAL TERMUX (10 min)

### 1.1 Instalação F-Droid (IMPORTANTE!)

```bash
# NUNCA use Google Play (desatualizado)
# Baixe via F-Droid: https://f-droid.org/en/packages/com.termux/
# Ou GitHub: https://github.com/termux/termux-app/releases

# Após instalar e abrir Termux:
apt-key add <(curl https://termux.org/packages/termux-apt-repo.asc)
apt update
apt upgrade -y
```

### 1.2 Instalar Ferramentas Base

```bash
#!/bin/bash
# Copie e cole isso no Termux

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
    git-credential-manager \
    openssh \
    postgresql \
    redis

# Verificar instalações
echo "✓ Verificando..."
node --version
npm --version
git --version
python3 --version
```

### 1.3 Configurar Git SSH (GitHub)

```bash
#!/bin/bash
# ~/.termux/scripts/setup-git-ssh.sh

echo "=== Configurando Git SSH ==="

# Gerar chave SSH Ed25519
ssh-keygen -t ed25519 -C "seu-email@example.com" -f ~/.ssh/id_ed25519 -N ""

# Copiar chave pública
echo "✓ Copie a chave abaixo e cole em GitHub → Settings → SSH Keys"
cat ~/.ssh/id_ed25519.pub

# Testar conexão
echo ""
echo "Pressione Enter após adicionar a chave no GitHub..."
read

ssh -T git@github.com

# Configurar Git global
git config --global user.name "Seu Nome"
git config --global user.email "seu-email@example.com"
git config --global core.editor "nano"

echo "✓ Git SSH configurado!"
```

**Execute:**
```bash
bash ~/.termux/scripts/setup-git-ssh.sh
```

### 1.4 Instalar Zsh + Powerlevel10k

```bash
#!/bin/bash
# ~/.termux/scripts/setup-zsh.sh

echo "=== Setup Zsh + Powerlevel10k ==="

pkg install -y zsh

# Oh-My-Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Powerlevel10k
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

# Plugins úteis
git clone https://github.com/zsh-users/zsh-autosuggestions \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

echo "✓ Zsh + Powerlevel10k instalado!"
```

**Execute:**
```bash
bash ~/.termux/scripts/setup-zsh.sh
chsh -s zsh
```

### 1.5 Configurar .zshrc (MAIN CONFIG)

```bash
#!/bin/bash
# Crie este arquivo: ~/.zshrc

cat > ~/.zshrc << 'ZSHRC_EOF'
# ========== OH-MY-ZSH ==========
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    command-not-found
    colored-man-pages
    extract
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ========== LLM CONFIG (Centralizado) ==========
export LLM_CONFIG_DIR="$HOME/.config/llm"

# Carregar variáveis de ambiente
if [ -f "$LLM_CONFIG_DIR/.env" ]; then
    set -a
    source "$LLM_CONFIG_DIR/.env"
    set +a
fi

# Carregar aliases LLM
if [ -f "$LLM_CONFIG_DIR/aliases/llm-aliases.sh" ]; then
    source "$LLM_CONFIG_DIR/aliases/llm-aliases.sh"
fi

# ========== HUB MCP (Central Knowledge) ==========
export HUB_DIR="$HOME/.termux/hub"
if [ -f "$HUB_DIR/aliases.sh" ]; then
    source "$HUB_DIR/aliases.sh"
fi

# ========== ALIASES ESSENCIAIS ==========
alias ls='ls -lah --color=auto'
alias ll='ls -lh'
alias pj='cd ~/projects'
alias dev='npm run dev'
alias build='npm run build'
alias test='npm test'
alias start='npm start'

# Git
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias gb='git branch'
alias gc='git commit -m'
alias ga='git add'
alias gd='git diff'
alias gco='git checkout'

# Utilidades
alias c='clear'
alias h='history'
alias v='vim'
alias n='nano'
alias mkdir='mkdir -pv'

# Dev
alias startx11='termux-x11 :0 -xstartup "dbus-launch --exit-with-session xfce4-session"'
alias ubuntu='proot-distro login ubuntu'
alias vim='nvim'

# ========== FUNÇÕES CUSTOM ==========

# Criar projeto Next.js rápido
next-project() {
    local name="${1:-my-app}"
    npx create-next-app@latest "$name" \
        --typescript \
        --tailwind \
        --app \
        --eslint \
        --import-alias "@/*" \
        --skip-install=false
    cd "$name"
    npm install @supabase/supabase-js @supabase/auth-helpers-nextjs
}

# Sincronizar config LLM
sync-llm() {
    echo "Sincronizando config LLM..."
    bash ~/.termux/hub/sync/termux-sync.sh
    echo "✓ Sincronizado!"
}

# Ver status de tudo
dev-status() {
    echo "=== DEV ENVIRONMENT STATUS ==="
    echo "Node.js: $(node --version)"
    echo "npm: $(npm --version)"
    echo "Git: $(git --version)"
    echo ""
    echo "=== LLM PROVIDERS ==="
    which claude && echo "Claude Code: ✅" || echo "Claude Code: ❌"
    which codex && echo "OpenAI Codex: ✅" || echo "OpenAI Codex: ❌"
    echo ""
    echo "=== HUB MCP ==="
    [ -d "$HUB_DIR" ] && echo "Hub MCP: ✅" || echo "Hub MCP: ❌"
    echo ""
    echo "=== STORAGE ==="
    echo "Home: $(du -sh ~ | cut -f1)"
    echo "Projects: $(du -sh ~/projects 2>/dev/null | cut -f1)"
}

# ========== PATH ==========
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"

# ========== FINAL ==========
# Welcome message
echo "🚀 Termux Dev Environment Ready!"
ZSHRC_EOF

# Aplicar
source ~/.zshrc
```

**Execute:**
```bash
bash ~/.termux/scripts/create-zshrc.sh
source ~/.zshrc
```

---

---

## 2. HUB MCP CENTRALIZADO (15 min)

**Sistema central para documentação + exemplos de todos os comandos**

### 2.1 Criar Estrutura do Hub

```bash
#!/bin/bash
# ~/.termux/scripts/setup-hub.sh

echo "=== Setup Hub MCP Centralizado ==="

# Criar diretórios
mkdir -p ~/.termux/hub/{wrappers,sync,cache,docs}

# Criar database.db (SQLite)
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

INSERT INTO skills (name, category, description, examples, usage) VALUES
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

INSERT INTO aliases (alias, command, description) VALUES
('pj', 'cd ~/projects', 'Ir para pasta de projetos'),
('dev', 'npm run dev', 'Iniciar dev server'),
('gs', 'git status', 'Ver status do git'),
('gp', 'git push', 'Enviar commits'),
('gl', 'git pull', 'Receber updates'),
('gc', 'git commit -m', 'Fazer commit'),
('startx11', 'termux-x11 :0 -xstartup "dbus-launch --exit-with-session xfce4-session"', 'Iniciar desktop X11');
SQL_EOF

# Criar database
sqlite3 ~/.termux/hub/database.db < ~/.termux/hub/init-db.sql

echo "✓ Hub structure criada!"
```

**Execute:**
```bash
bash ~/.termux/scripts/setup-hub.sh
```

### 2.2 Hub Main Script

```bash
#!/bin/bash
# ~/.termux/hub/hub.sh

HUB_DB="$HOME/.termux/hub/database.db"

hub() {
    local action="$1"
    local query="$2"

    case "$action" in
        ask)
            # Buscar no SQLite
            sqlite3 "$HUB_DB" \
                "SELECT description, usage, examples FROM skills WHERE name LIKE '%$query%' LIMIT 1"
            ;;
        search)
            # Buscar por categoria
            sqlite3 "$HUB_DB" \
                "SELECT name, description FROM skills WHERE category='$query' OR description LIKE '%$query%'"
            ;;
        list)
            # Listar tudo
            sqlite3 "$HUB_DB" "SELECT DISTINCT category FROM skills"
            ;;
        list-category)
            # Listar por categoria
            sqlite3 "$HUB_DB" \
                "SELECT name FROM skills WHERE category='$query'"
            ;;
        add)
            # Adicionar skill
            local name="$2"
            local category="$3"
            local description="$4"
            sqlite3 "$HUB_DB" \
                "INSERT INTO skills (name, category, description) VALUES ('$name', '$category', '$description')"
            echo "✓ Skill '$name' adicionado!"
            ;;
        *)
            echo "Hub MCP - Central Knowledge System"
            echo ""
            echo "Uso:"
            echo "  hub ask <comando>        - Buscar documentação"
            echo "  hub search <palavra>     - Buscar por palavra-chave"
            echo "  hub list                 - Listar categorias"
            echo "  hub list-category <cat>  - Listar skills de categoria"
            echo "  hub add <name> <cat> <desc> - Adicionar skill"
            echo ""
            echo "Exemplos:"
            echo "  hub ask git clone"
            echo "  hub search npm"
            echo "  hub list-category git"
            ;;
    esac
}

# Se chamado como script direto
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && hub "$@"
```

**Tornar executável:**
```bash
chmod +x ~/.termux/hub/hub.sh
echo 'alias hub="~/.termux/hub/hub.sh"' >> ~/.zshrc
```

### 2.3 Hub Aliases

```bash
#!/bin/bash
# ~/.termux/hub/aliases.sh

# Hub functions
alias hub='~/.termux/hub/hub.sh'
alias hub-ask='hub ask'
alias hub-search='hub search'
alias hub-list='hub list'
alias hub-add='hub add'

# Git examples
hub-git-clone() {
    echo "git clone https://github.com/user/repo"
    echo "git clone https://github.com/user/repo my-custom-name"
}

# NPM examples
hub-npm() {
    echo "npm install              # Instalar dependências"
    echo "npm install package-name # Instalar pacote específico"
    echo "npm run dev              # Rodar dev server"
    echo "npm run build            # Build produção"
    echo "npm test                 # Rodar testes"
}

# Docker examples
hub-docker() {
    echo "docker ps                # Listar containers"
    echo "docker run -it ubuntu    # Rodar container interativo"
    echo "docker build -t name .   # Build image"
}
```

---

---

## 3. DUAL-SHELL TERMUX ↔ UBUNTU (20 min)

**Sincronização perfeita entre Termux nativo e Ubuntu proot-distro**

### 3.1 Instalar proot-distro

```bash
#!/bin/bash
# ~/.termux/scripts/setup-proot.sh

echo "=== Setup proot-distro ==="

# Instalar proot-distro
pkg install -y proot-distro

# Instalar Ubuntu
proot-distro install ubuntu

# Configurar para usar home compartilhada
proot-distro login ubuntu

# Dentro do Ubuntu:
# apt update && apt upgrade -y
# apt install -y nodejs npm git build-essential

# Sair
# exit
```

**Execute:**
```bash
bash ~/.termux/scripts/setup-proot.sh
```

### 3.2 Script de Sincronização

```bash
#!/bin/bash
# ~/.termux/hub/sync/termux-sync.sh

echo "=== Sincronizando Termux ↔ Ubuntu ==="

TERMUX_HOME="$HOME"
UBUNTU_HOME="/data/data/com.termux/files/home/ubuntu/root"  # Ajustar conforme seu setup

# Criar symlinks para shared directories
echo "Criando symlinks..."

# Projects
ln -sf "$TERMUX_HOME/projects" "$UBUNTU_HOME/projects" 2>/dev/null
ln -sf "$TERMUX_HOME/.config" "$UBUNTU_HOME/.config" 2>/dev/null
ln -sf "$TERMUX_HOME/.ssh" "$UBUNTU_HOME/.ssh" 2>/dev/null

# Sincronizar .env files
if [ -f "$TERMUX_HOME/.config/llm/.env" ]; then
    cp "$TERMUX_HOME/.config/llm/.env" "$UBUNTU_HOME/.config/llm/.env"
    chmod 600 "$UBUNTU_HOME/.config/llm/.env"
fi

# Sincronizar Hub MCP
rsync -av "$TERMUX_HOME/.termux/hub/" "$UBUNTU_HOME/.termux/hub/" \
    --exclude="cache/*" \
    --exclude="*.log" 2>/dev/null

echo "✓ Sincronização completa!"
echo ""
echo "Para testar:"
echo "  proot-distro login ubuntu"
echo "  ls ~/projects  # Deve funcionar"
```

**Execute:**
```bash
chmod +x ~/.termux/hub/sync/termux-sync.sh
bash ~/.termux/hub/sync/termux-sync.sh
```

### 3.3 Usar Ubuntu via Alias

```bash
# Já adicionado em ~/.zshrc
alias ubuntu='proot-distro login ubuntu'

# Uso:
ubuntu
# Agora está no Ubuntu!
ls ~/projects  # Acessa os mesmos projetos
exit           # Volta ao Termux
```

---

---

## 4. CLI LLMS UNIFICADO (10 min)

**Todos os LLMs com APIs unificadas e compartilhadas**

### 4.1 Instalar CLIs Oficiais

```bash
#!/bin/bash
# ~/.termux/scripts/setup-llms.sh

echo "=== Setup LLM CLIs ==="

# Claude Code (RECOMENDADO)
npm install -g claude-code

# OpenAI CLI
npm install -g @openai/openai

# Groq CLI
npm install -g @groq/groq-cli

# Verificar instalações
echo ""
echo "=== Verificando instalações ==="
which claude && echo "✓ Claude Code" || echo "✗ Claude Code"
which codex && echo "✓ OpenAI Codex" || echo "✗ OpenAI Codex"
which groq && echo "✓ Groq CLI" || echo "✗ Groq CLI"
```

**Execute:**
```bash
bash ~/.termux/scripts/setup-llms.sh
```

### 4.2 Criar Config Centralizada LLM

```bash
#!/bin/bash
# ~/.config/llm/config.json

mkdir -p ~/.config/llm

cat > ~/.config/llm/config.json << 'JSON_EOF'
{
  "llm_providers": {
    "claude": {
      "cli": "claude",
      "enabled": true,
      "default": true,
      "model": "claude-opus-4.5"
    },
    "openai": {
      "cli": "openai",
      "enabled": true,
      "model": "gpt-5.1"
    },
    "groq": {
      "cli": "groq",
      "enabled": true,
      "model": "llama-3.3-70b"
    },
    "gemini": {
      "method": "curl",
      "enabled": true,
      "model": "gemini-2.5-flash"
    }
  },
  "aliases": {
    "cld": "claude",
    "cod": "openai",
    "grq": "groq",
    "gem": "gemini"
  }
}
JSON_EOF

echo "✓ Config criada!"
```

### 4.3 Arquivo .env Centralizado

```bash
#!/bin/bash
# ~/.config/llm/.env (GITIGNORE!)

cat > ~/.config/llm/.env << 'ENV_EOF'
# ===== CLAUDE (Anthropic) =====
export ANTHROPIC_API_KEY="sk-ant-xxxxx-xxxxx"

# ===== OPENAI =====
export OPENAI_API_KEY="sk-xxxxx-xxxxx"

# ===== GROQ =====
export GROQ_API_KEY="gsk-xxxxx-xxxxx"

# ===== GEMINI (Google) =====
export GOOGLE_API_KEY="AIzaSyxxxxx-xxxxx"

# ===== DEFAULTS =====
export DEFAULT_LLM_PROVIDER="claude"
ENV_EOF

chmod 600 ~/.config/llm/.env
```

### 4.4 LLM Aliases Unificados

```bash
#!/bin/bash
# ~/.config/llm/aliases/llm-aliases.sh

# ===== CLAUDE CODE =====
alias cld='claude'
alias cld-code='claude --code'
alias cld-chat='claude -p'

# ===== OPENAI =====
alias cod='openai'
alias cod-fix='openai --suggest'

# ===== GROQ =====
alias grq='groq'
alias grq-fast='groq --model llama-3.3-70b'

# ===== GEMINI (via curl) =====
gemini-ask() {
    local query="$@"
    curl -s "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent" \
        -H "Content-Type: application/json" \
        -H "x-goog-api-key: $GOOGLE_API_KEY" \
        -d "{\"contents\": [{\"parts\": [{\"text\": \"$query\"}]}]}" | jq -r '.contents[0].parts[0].text' 2>/dev/null || echo "Erro ao chamar Gemini"
}
alias gem='gemini-ask'

# ===== UNIVERSAL COMMAND =====
ask() {
    local provider="${DEFAULT_LLM_PROVIDER:-claude}"
    local query="$@"
    
    case "$provider" in
        claude)
            echo "$query" | claude -
            ;;
        groq)
            grq "$query"
            ;;
        openai)
            cod "$query"
            ;;
        gemini)
            gem "$query"
            ;;
        *)
            echo "Provider desconhecido: $provider"
            ;;
    esac
}

# ===== UTILITIES =====
llm-status() {
    echo "=== LLM Status ==="
    which claude && echo "Claude: ✅" || echo "Claude: ❌"
    which openai && echo "OpenAI: ✅" || echo "OpenAI: ❌"
    which groq && echo "Groq: ✅" || echo "Groq: ❌"
    [ -n "$GOOGLE_API_KEY" ] && echo "Gemini: ✅" || echo "Gemini: ❌"
}

llm-use() {
    local provider="$1"
    case "$provider" in
        claude|groq|openai|gemini)
            export DEFAULT_LLM_PROVIDER="$provider"
            echo "Switched to $provider"
            ;;
        *)
            echo "Use: llm-use [claude|groq|openai|gemini]"
            ;;
    esac
}

llm-config-show() {
    cat ~/.config/llm/config.json | jq '.'
}
```

---

---

## 5. DEV WEBAPP NEXT.JS + SUPABASE (15 min)

### 5.1 Criar Projeto Next.js

```bash
#!/bin/bash
# Copie e cole no Termux

# Criar projeto
npx create-next-app@latest my-webapp \
    --typescript \
    --tailwind \
    --app \
    --eslint

# Entrar na pasta
cd my-webapp

# Instalar Supabase
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs

# Instalar outras dependencies úteis
npm install zod react-hook-form sonner
```

### 5.2 Setup Supabase

```bash
#!/bin/bash
# .env.local (criar manualmente ou via script)

cat > .env.local << 'ENVLOCAL_EOF'
# ===== SUPABASE =====
NEXT_PUBLIC_SUPABASE_URL=https://seu-projeto.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=seu-chave-anonima-aqui
SUPABASE_SERVICE_ROLE_KEY=sua-chave-service-role-aqui

# ===== GEMINI (se usar) =====
NEXT_PUBLIC_GEMINI_API_KEY=sua-chave-gemini

# ===== CLAUDE (se usar) =====
NEXT_PUBLIC_CLAUDE_API_KEY=sua-chave-claude
ENVLOCAL_EOF

# Nunca commitar .env.local!
echo ".env.local" >> .gitignore
```

**Para obter as chaves:**
1. Ir em https://supabase.com
2. Criar novo projeto
3. Settings → API → copiar as chaves

### 5.3 Estrutura Básica Supabase Client

```typescript
// lib/supabase/client.ts

import { createBrowserClient } from '@supabase/ssr'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!

export const createClient = () =>
  createBrowserClient(supabaseUrl, supabaseAnonKey)
```

```typescript
// lib/supabase/server.ts

import { createServerClient, CookieOptions } from '@supabase/ssr'
import { cookies } from 'next/headers'

export const createClient = () => {
  const cookieStore = cookies()

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll()
        },
        setAll(cookiesToSet) {
          try {
            cookiesToSet.forEach(({ name, value, options }) =>
              cookieStore.set(name, value, options)
            )
          } catch {}
        },
      },
    }
  )
}
```

### 5.4 Rodar Dev Server

```bash
# No projeto ~/projects/my-webapp

npm run dev

# Saída esperada:
#   ▲ Next.js 16.x.x
#   - Local:        http://localhost:3000
#   - Environments: .env.local
#   ready started server on 0.0.0.0:3000

# Acessar no navegador:
# http://127.0.0.1:3000
```

---

---

## 6. CODE-SERVER (VS CODE WEB) (10 min)

**VS Code rodando no navegador (MELHOR que X11)**

### 6.1 Instalar Code-Server

```bash
#!/bin/bash
# ~/.termux/scripts/setup-code-server.sh

echo "=== Setup Code-Server ==="

npm install -g code-server

# Criar config
mkdir -p ~/.config/code-server

cat > ~/.config/code-server/config.yaml << 'YAML_EOF'
bind-addr: 127.0.0.1:8080
auth: password
password: sua-senha-super-segura-aqui
cert: false
YAML_EOF

echo "✓ Code-Server instalado!"
echo "Acesse: http://127.0.0.1:8080"
```

**Execute:**
```bash
bash ~/.termux/scripts/setup-code-server.sh
```

### 6.2 Rodar Code-Server

```bash
#!/bin/bash
# Adicionar ao ~/.zshrc

alias code-server="code-server --bind-addr 127.0.0.1:8080"

# Iniciar
code-server

# Acessar navegador
# http://127.0.0.1:8080
# Digite a senha
```

### 6.3 VS Code Extensions Recomendadas

Ao acessar code-server, instale via interface:
- Prettier - Code formatter
- ESLint
- Tailwind CSS IntelliSense
- Thunder Client (testar APIs)
- Database Client (visualizar Supabase)

---

---

## 7. ALIASES E WORKFLOW (5 min)

### 7.1 Aliases Recomendados

```bash
#!/bin/bash
# Já deve estar em ~/.zshrc

# ===== PROJETOS =====
alias pj='cd ~/projects'
alias pj-new='cd ~/projects && mkdir'
alias pj-ls='ls ~/projects'

# ===== DESENVOLVIMENTO =====
alias dev='npm run dev'
alias build='npm run build'
alias test='npm test'
alias lint='npm run lint'
alias start='npm start'

# ===== GIT (ESSENCIAL) =====
alias gs='git status'
alias gp='git push'
alias gl='git pull'
alias gb='git branch'
alias gc='git commit -m'
alias ga='git add'
alias gd='git diff'
alias gco='git checkout'
alias glg='git log --graph --oneline --all'

# ===== TERMUX/SISTEMA =====
alias c='clear'
alias h='history'
alias mkdir='mkdir -pv'
alias rm='rm -iv'
alias mv='mv -iv'
alias cp='cp -iv'
alias du='du -sh'

# ===== DEV TOOLS =====
alias vim='nano'  # Use nano se não souber vim
alias ls='ls -lah --color=auto'
alias ll='ls -lh'
alias la='ls -la'

# ===== CUSTOM FUNCTIONS =====

# Criar projeto Next.js rápido
next-project() {
    local name="${1:-my-app}"
    npx create-next-app@latest "$name" \
        --typescript \
        --tailwind \
        --app \
        --eslint
    cd "$name"
    npm install @supabase/supabase-js
    echo "✓ Projeto '$name' criado!"
}

# Status do dev environment
dev-status() {
    echo "=== DEV STATUS ==="
    echo "Node: $(node -v)"
    echo "npm: $(npm -v)"
    echo "Git: $(git --version | awk '{print $3}')"
    echo ""
    echo "=== LLM PROVIDERS ==="
    which claude && echo "Claude: ✅" || echo "Claude: ❌"
    which openai && echo "OpenAI: ✅" || echo "OpenAI: ❌"
    which groq && echo "Groq: ✅" || echo "Groq: ❌"
}

# Sincronizar tudo
sync-all() {
    echo "Sincronizando..."
    bash ~/.termux/hub/sync/termux-sync.sh
    echo "✓ Tudo sincronizado!"
}

# Backup de projetos
backup-projects() {
    local backup_date=$(date +%Y%m%d_%H%M%S)
    tar -czf ~/projects_backup_$backup_date.tar.gz ~/projects/
    echo "✓ Backup: projects_backup_$backup_date.tar.gz"
}
```

### 7.2 Workflow Diário

```bash
# MANHÃ - Abrir Termux
$ zsh  # Abre com Powerlevel10k

# Ir para projetos
$ pj
$ ls

# Ver estado do projeto
$ gs  # git status

# Começar desenvolvimento
$ dev  # npm run dev
# Dev server roda em localhost:3000

# EM OUTRA ABA
# Abrir VS Code web
$ code-server
# Acessa http://127.0.0.1:8080

# Fazer mudanças no projeto
# (editar via code-server ou vim)

# Testar
$ test  # npm test

# Commit
$ ga .        # git add .
$ gc "feat: nova feature"  # git commit

# Push
$ gp          # git push

# Vercel + GitHub automático
# Preview deployment aparece em PR

# APÓS MERGE
# Deploy automático em produção
```

---

---

## 8. AI HUB CENTRALIZADO (20 min)

**Gateway local que centraliza TODOS os LLMs**

### 8.1 Setup Docker Compose (Simplificado)

```yaml
# ~/.aihub/docker-compose.yml

version: '3.8'

services:
  ollama:
    image: ollama/ollama:latest
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0:11434

volumes:
  ollama_data:
```

```bash
# Rodar
cd ~/.aihub
docker-compose up -d

# Verificar
curl http://localhost:11434/api/tags
```

### 8.2 Config Centralizada AI Hub

```json
{
  "~/.aihub/config.json":

  {
    "server": {
      "host": "0.0.0.0",
      "port": 5555,
      "api_version": "v1"
    },
    "providers": {
      "claude": {
        "enabled": true,
        "priority": 1,
        "api_key_env": "ANTHROPIC_API_KEY"
      },
      "groq": {
        "enabled": true,
        "priority": 2,
        "api_key_env": "GROQ_API_KEY"
      },
      "openai": {
        "enabled": true,
        "priority": 3,
        "api_key_env": "OPENAI_API_KEY"
      },
      "ollama": {
        "enabled": true,
        "priority": 4,
        "base_url": "http://localhost:11434"
      }
    },
    "routing": {
      "default": "claude",
      "code": "groq",
      "research": "claude",
      "budget": "ollama",
      "fast": "groq"
    },
    "caching": {
      "enabled": true,
      "ttl_seconds": 3600
    }
  }
}
```

### 8.3 Script de Setup AI Hub

```bash
#!/bin/bash
# ~/.aihub/scripts/setup.sh

echo "=== Setup AI Hub ==="

mkdir -p ~/.aihub/{config,data,logs,scripts}

# Copiar configs
cat > ~/.aihub/config.json << 'JSON_EOF'
{
  "server": {"port": 5555},
  "providers": {"claude": {}, "groq": {}, "openai": {}, "ollama": {}},
  "routing": {"default": "claude"}
}
JSON_EOF

# Criar arquivo .env
cat > ~/.aihub/.env << 'ENV_EOF'
ANTHROPIC_API_KEY=sk-ant-xxxxx
GROQ_API_KEY=gsk-xxxxx
OPENAI_API_KEY=sk-xxxxx
GOOGLE_API_KEY=AIzaSyxxxxx
ENV_EOF

chmod 600 ~/.aihub/.env

echo "✓ AI Hub setup completo!"
echo "Config em: ~/.aihub/"
```

---

---

## 9. TROUBLESHOOTING & DICAS

### Problema: npm install muito lento

```bash
# Solução 1: Use npm ci (mais rápido)
npm ci --prefer-offline

# Solução 2: Configure npm
npm config set registry https://registry.npmjs.org/
npm cache clean --force

# Solução 3: Use pnpm (melhor performance)
npm install -g pnpm
pnpm install
```

### Problema: Node.js consome muita RAM

```bash
# Limitar RAM (set de 256MB a 512MB)
export NODE_OPTIONS="--max-old-space-size=512"

# Verificar uso
ps aux | grep node
```

### Problema: Git slow/timeout

```bash
# Aumentar timeout
git config --global http.postBuffer 524288000
git config --global http.maxRequestBuffer 524288000

# Usar SSH em vez de HTTPS
git config --global url."git@github.com:".insteadOf "https://github.com/"
```

### Problema: Termux/Ubuntu fora de sincronização

```bash
# Re-sincronizar
bash ~/.termux/hub/sync/termux-sync.sh

# Verificar symlinks
ls -la ~/projects
```

### Problema: X11 tela preta

```bash
# NÃO é bug grave! Use code-server em vez disso:
code-server
# Acesse http://127.0.0.1:8080
# Melhor experiência + menos RAM
```

### Problema: Supabase connection refused

```bash
# Verificar internet
ping 8.8.8.8

# Verificar chaves em .env.local
cat .env.local | grep SUPABASE

# Testar conexão
curl https://seu-projeto.supabase.co/rest/v1/health
```

### Problema: Storage cheio

```bash
# Ver uso
du -sh ~/
du -sh ~/.npm
du -sh ~/.cache
du -sh node_modules

# Limpar
npm cache clean --force
rm -rf node_modules
npm install  # Reinstalar
```

### Dica: Aumentar Performance

```bash
# 1. Use RAM disk para temporários
export TMPDIR=/dev/shm

# 2. Desabilitar swap
export NODE_OPTIONS="--no-warnings"

# 3. Usar SSD externo via USB-C (se tiver)
# Montar em /mnt/external
# Mover node_modules pra lá

# 4. Usar Samsung DeX
# Mouse/teclado = melhor produtividade
```

### Dica: Monitorar Resource Usage

```bash
#!/bin/bash
# ~/.termux/scripts/monitor.sh

watch -n 1 'echo "=== MEMORY ==="; free -h; echo ""; echo "=== CPU ==="; top -bn1 | head -5; echo ""; echo "=== DISK ==="; df -h /'
```

---

---

## 📚 REFERÊNCIAS

- **Termux Official:** https://termux.dev
- **Node.js:** https://nodejs.org
- **Next.js:** https://nextjs.org
- **Supabase:** https://supabase.com
- **Vercel:** https://vercel.com
- **GitHub:** https://github.com
- **Samsung DeX:** https://www.samsung.com/global/galaxy/apps/dex
- **Code-Server:** https://coder.com/docs/code-server

---

---

## 🎓 PRÓXIMOS PASSOS

1. ✅ Setup Inicial (20 min)
2. ✅ Hub MCP (15 min)
3. ✅ Dual-Shell (20 min)
4. ✅ LLM CLI (10 min)
5. ✅ Next.js + Supabase (15 min)
6. ✅ Code-Server (10 min)
7. ✅ Workflow + Aliases (5 min)
8. ✅ AI Hub (20 min)

**Total:** ~2 horas ⏱️

---

## ⚡ QUICK START (TL;DR)

```bash
# 1. Termux Setup (5 min)
pkg update && pkg upgrade -y
pkg install -y git nodejs-lts npm zsh build-essential

# 2. Zsh + SSH (5 min)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
ssh-keygen -t ed25519 -C "seu-email@example.com"
# Adicionar chave pública no GitHub

# 3. Hub MCP (3 min)
mkdir -p ~/.termux/hub
sqlite3 ~/.termux/hub/database.db ".tables"

# 4. Projeto Next.js (5 min)
npx create-next-app@latest my-webapp --typescript --tailwind --app
cd my-webapp
npm install @supabase/supabase-js

# 5. Code-Server (2 min)
npm install -g code-server
code-server

# 6. Abrir navegador
# http://127.0.0.1:8080  → VS Code
# http://127.0.0.1:3000  → Dev server

# PRONTO! 🚀
```

---

**Criado:** Fevereiro 23, 2026  
**Testado em:** Samsung Galaxy S24 Ultra  
**Termux Version:** 2025.01.18+  
**Status:** ✅ Completo e Pronto para Usar

---

