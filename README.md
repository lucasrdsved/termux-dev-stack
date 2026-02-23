# 🚀 Termux Dev Stack Completo

Documentação e scripts para transformar seu Termux em um ambiente de desenvolvimento completo. Baseado no setup para Samsung Galaxy S24 Ultra.

## 📦 O que está incluído?

- **Setup Inicial:** Node.js, Git, Python, Build-essential, etc.
- **Zsh + Oh-My-Zsh:** Com Powerlevel10k, autosuggestions e syntax highlighting.
- **Hub MCP:** Sistema centralizado de conhecimento via SQLite.
- **Dual-Shell:** Sincronização entre Termux e Ubuntu (proot-distro).
- **CLI LLMs:** Configuração centralizada para Claude, OpenAI, Groq e Gemini.
- **Webapp Stack:** Suporte para Next.js + Supabase.
- **Code-Server:** VS Code rodando no navegador.

## ⚡ Instalação Rápida

Para instalar todo o ambiente automaticamente, abra seu Termux e execute o comando abaixo:

```bash
curl -fsSL https://raw.githubusercontent.com/lucasrdsved/termux-dev-stack/master/install.sh | bash
```



## 🛠️ Uso Básico

- `pj`: Ir para a pasta de projetos.
- `gs`: Status do Git.
- `dev`: Rodar `npm run dev`.
- `hub ask <comando>`: Buscar documentação no Hub local.
- `ubuntu`: Entrar no shell do Ubuntu.
- `code-server`: Iniciar o VS Code web.

## 📄 Documentação Completa

O guia completo original está disponível no arquivo [TERMUX-DEV-STACK-COMPLETO.md](./TERMUX-DEV-STACK-COMPLETO.md).

---
Criado por Manus AI.
