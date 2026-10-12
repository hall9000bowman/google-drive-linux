# Google Drive Desktop Agent para Linux 🐧☁️

> Um cliente e agente desktop nativo e não oficial do Google Drive para Linux, inspirado no aplicativo oficial para Windows/Mac — com streaming sob demanda, cache de arquivos VFS, indicador na bandeja do sistema (systray), atalhos na barra lateral do gerenciador de arquivos e sincronização em segundo plano.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux-orange.svg)](#)
[![Python](https://img.shields.io/badge/Python-3.8+-brightgreen.svg)](#)

[Read in English](README.md)

> [!NOTE]
> **Projeto não oficial.** Esta é uma ferramenta independente, feita pela comunidade. Não é afiliada, endossada nem suportada pelo Google. É construída sobre o [rclone](https://rclone.org/).
>
> **Software em fase beta. Use por sua conta e risco.** Foi testado em poucas configurações. Mantenha backup dos arquivos importantes e [relate problemas](https://github.com/hall9000bowman/google-drive-linux/issues).

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

Se o `rclone` não estiver instalado, o instalador baixa a versão mais recente e verifica o checksum SHA-256 e, quando o `gpg` está disponível, a assinatura oficial do rclone antes de instalá-lo em `~/.local/bin`.

---

## 🔑 Configuração e Autenticação

> [!IMPORTANT]
> O client ID compartilhado do rclone para o Google Drive está sendo descontinuado e deixará de funcionar durante 2026. Antes de executar o setup, [crie seu próprio client ID OAuth do Google](https://rclone.org/drive/#making-your-own-client-id) e preencha `client_id` / `client_secret` no arquivo de configuração (veja [Arquivo de Configuração](#%EF%B8%8F-arquivo-de-configuração) abaixo). Isso também garante uma cota de API dedicada, deixando o drive mais rápido.

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

# Reler toda a lista de arquivos do Drive em segundo plano (ou apenas uma pasta)
google-drive-agent refresh
google-drive-agent refresh "Trabalho/Relatorios"

# Abrir o Google Drive na Web pelo navegador
google-drive-agent open-web

# Montar ou desmontar manualmente
google-drive-agent mount
google-drive-agent unmount

# Iniciar o ícone na bandeja do sistema (systray)
google-drive-agent tray

# Gerenciar o serviço systemd em segundo plano
google-drive-agent service install
google-drive-agent service remove
google-drive-agent service status
google-drive-agent service start
google-drive-agent service stop

# Adicionar ou remover o atalho na barra lateral do gerenciador de arquivos
google-drive-agent bookmark add
google-drive-agent bookmark remove
```

Quando o serviço systemd está habilitado, ele é o responsável pela montagem: `mount`, `unmount` e o botão de montar da bandeja iniciam e param o serviço em vez de abrir um segundo processo do rclone.

---

## ⚙️ Arquivo de Configuração

A configuração fica em `~/.config/google-drive-agent/config.json` (ou em `$XDG_CONFIG_HOME`). O arquivo é privado (`0600`) porque pode conter o seu client secret OAuth. As alterações valem a partir da próxima montagem.

```json
{
  "remote_name": "gdrive",
  "mount_path": "~/GoogleDrive",
  "vfs_cache_mode": "full",
  "vfs_cache_max_size": "50G",
  "vfs_cache_max_age": "72h",
  "vfs_cache_min_free_space": "10G",
  "vfs_read_chunk_size": "32M",
  "vfs_read_chunk_size_limit": "2G",
  "buffer_size": "16M",
  "drive_chunk_size": "64M",
  "dir_cache_time": "72h",
  "poll_interval": "15s",
  "export_formats": "link.html",
  "log_level": "NOTICE",
  "rc_port": 5572,
  "client_id": "",
  "client_secret": ""
}
```

- **`mount_path`**: Pasta onde o drive virtual é montado (padrão: `~/GoogleDrive`).
- **`vfs_cache_max_size`**: Espaço máximo em disco para arquivos em cache (ex.: `25G`, `50G`, `100G`).
- **`vfs_cache_min_free_space`**: Remove arquivos do cache para manter pelo menos esse espaço livre no disco. Use `""` para desativar (necessário em versões muito antigas do rclone).
- **`buffer_size`**: Leitura antecipada em memória por arquivo aberto. Fica pequeno porque o cache VFS já guarda os dados em disco.
- **`drive_chunk_size`**: Tamanho dos blocos de upload. Valores maiores aceleram uploads grandes, mas usam essa quantidade de memória por upload simultâneo. Use `""` para o padrão do rclone.
- **`export_formats`**: Formato dos Documentos Google (`link.html` abre direto no navegador; também é possível usar `docx,xlsx,pptx`).
- **`log_level`**: Nível de log do rclone: `DEBUG`, `INFO`, `NOTICE` ou `ERROR`.
- **`rc_port`**: Porta local da API de controle remoto do rclone (usada pelo *Atualizar*). Escuta apenas em `127.0.0.1` e é protegida por senha.
- **`client_id` / `client_secret`**: Suas próprias credenciais OAuth do Google Cloud. Fortemente recomendado (veja acima).

Valores inválidos ou desconhecidos geram um aviso e são substituídos pelo padrão. Um arquivo com JSON inválido nunca é sobrescrito.

---

## 🩺 Solução de Problemas

- **Visão geral**: `google-drive-agent status`
- **Logs (serviço systemd)**: `journalctl --user -u google-drive.service`
- **Logs (montagem manual / bandeja)**: `~/.cache/google-drive-agent/rclone.log`
- **"Transport endpoint is not connected"**: o rclone foi encerrado inesperadamente. `google-drive-agent mount` limpa a montagem antiga e monta novamente.
- **O Atualizar diz que as credenciais foram rejeitadas**: o drive foi montado por uma versão anterior. Desmonte e monte novamente.

---

## 🛡️ Privacidade e Segurança

- **Sem Servidores Intermediários**: Toda a comunicação ocorre diretamente entre o seu computador e as APIs oficiais do Google.
- **Nenhum Rastreamento**: Zero telemetria, análise de uso ou logs enviados para terceiros.
- **Credenciais Seguras**: Os tokens OAuth são mantidos localmente pelo rclone (`~/.config/rclone/rclone.conf`). A configuração do agente e as credenciais geradas só podem ser lidas pelo seu usuário.
- **API Local Protegida**: A API de controle remoto do rclone escuta apenas em `127.0.0.1` e exige uma senha aleatória (guardada em `~/.config/google-drive-agent/rc-auth.json`). Outros usuários locais e sites abertos no navegador não conseguem usá-la para ler seu token ou alterar seus arquivos. A senha é passada ao rclone por variável de ambiente e nunca aparece na lista de processos.
- **Downloads Verificados**: O instalador confere o download do rclone com os checksums assinados da versão.
- **Código Aberto**: Código Python e Shell 100% auditável sob licença MIT.

---

## 🗑️ Desinstalação

Para remover o agente, o serviço systemd, os atalhos e o favorito da barra lateral:

```bash
./uninstall.sh
```

Sua configuração, o cache e o remote do rclone são mantidos. O desinstalador mostra os comandos para apagá-los também.

---

## ™️ Marcas Registradas

Google Drive™ é uma marca registrada do Google LLC, usada aqui apenas para descrever o serviço ao qual esta ferramenta se conecta. O ícone do aplicativo é um desenho original criado para este projeto e distribuído sob a mesma licença MIT.

---

## 📄 Licença

Distribuído sob a [Licença MIT](LICENSE).
