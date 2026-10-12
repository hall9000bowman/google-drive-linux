# Google Drive Desktop Agent para Linux 🐧☁️

> Um cliente e agente desktop nativo do Google Drive para Linux equivalente à versão oficial para Windows/Mac ("Drive para computador") — com streaming sob demanda, cache de arquivos VFS, indicador na bandeja do sistema (systray), atalhos na barra lateral do gerenciador de arquivos e sincronização em segundo plano.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](#)
[![Python](https://img.shields.io/badge/Python-3.8+-brightgreen.svg)](#)

[Read in English](README.md)

---

## 🌟 Principais Recursos

- **Streaming sob Demanda (Cache VFS)**: Acesse todo o seu Google Drive sem lotar o armazenamento do seu computador. Os arquivos são baixados de forma transparente apenas quando você os abre e salvos em cache local.
- **Sincronização Automática Bidirecional**: Edite ou salve arquivos em qualquer programa local (LibreOffice, VS Code, GIMP, editores de texto) e as alterações sobem para a nuvem em segundo plano automaticamente.
- **Detecção Rápida de Alterações**: Alterações feitas no navegador ou pelo celular aparecem na sua máquina em menos de 15 segundos.
- **Suporte a Documentos / Planilhas / Apresentações Google**: Arquivos nativos do Google Workspace são exportados como links web (`.link.html`) que abrem diretamente no seu navegador padrão ao dar duplo clique.
- **Integração com o Gerenciador de Arquivos**: Adiciona o `Google Drive` automaticamente à barra lateral do seu gerenciador (Nautilus, Dolphin, Thunar e caixas de diálogo Abrir/Salvar).
- **Bandeja do Sistema (Systray)**: Indicador com status em tempo real, medidor de cota de armazenamento usada/livre, atalhos rápidos e botão para forçar sincronização.
- **Serviço em Segundo Plano via Systemd**: Executa de forma resiliente como serviço `systemd --user` com início automático no login e reinicialização automática em caso de falha.
- **Instalação sem Root (Zero Sudo)**: Instala 100% no espaço de usuário (`~/.local/bin`, `~/.config`). Não requer privilégios de administrador!

---

## 🚀 Instalação Rápida

Clone o repositório e execute o instalador:

```bash
git clone https://github.com/hall9000bowman/google-drive-linux.git
cd google-drive-linux
./install.sh
```

---

## 🔑 Configuração e Autenticação

Após a instalação, conecte sua conta Google executando:

```bash
google-drive-agent setup
```

1. Seu navegador padrão será aberto automaticamente na página de login do Google.
2. Faça login na sua conta e clique em **Permitir**.
3. O Google Drive será montado imediatamente em `~/GoogleDrive` e começará a transmitir seus arquivos!

---

## 💻 Comandos Úteis

O executável `google-drive-agent` oferece controle total via linha de comando:

```bash
# Abrir a pasta do Google Drive no gerenciador de arquivos (monta se necessário)
google-drive-agent open

# Ver status da conexão, tamanho do cache e cota de armazenamento
google-drive-agent status

# Forçar atualização de cache e sincronizar novidades da nuvem
google-drive-agent refresh

# Abrir o Google Drive na Web pelo navegador
google-drive-agent open-web

# Montar ou desmontar manualmente
google-drive-agent mount
google-drive-agent unmount

# Iniciar o ícone na bandeja do sistema (systray)
google-drive-agent tray

# Gerenciar o serviço systemd em segundo plano
google-drive-agent service status
google-drive-agent service start
google-drive-agent service stop
```

---

## 🛡️ Privacidade e Segurança

- **Sem Servidores Intermediários**: Toda a comunicação ocorre diretamente entre o seu computador e as APIs oficiais do Google.
- **Nenhum Rastreamento**: Zero telemetria, análise de uso ou logs enviados para terceiros.
- **Credenciais Seguras**: As chaves e tokens OAuth são mantidos exclusivamente na sua máquina local (`~/.config/rclone/rclone.conf`).
- **Código Aberto**: Código Python e Shell 100% auditável sob licença MIT.

---

## 🗑️ Desinstalação

Para desinstalar o agente e remover os atalhos:

```bash
./uninstall.sh
```

---

## 📄 Licença

Distribuído sob a [Licença MIT](LICENSE).
