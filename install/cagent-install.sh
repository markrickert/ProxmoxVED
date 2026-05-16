#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Mark Rickert (markrickert)
# License: MIT | https://github.com/community-scripts/ProxmoxVED/raw/main/LICENSE
# Source: https://docs.claude.com/en/docs/claude-code

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# Disable the spinner — this script runs unattended and the animation produces
# noise in logs. msg_info/msg_ok text output is preserved.
spinner() { :; }

# Patch set_std_mode before verb_ip6 calls it: when this install script runs
# via `lxc-attach -- bash -c "..."`, BASH_SOURCE is an empty array (0 elements).
# The default PS4 uses ${BASH_SOURCE} which triggers "unbound variable" once
# set -u is active (enabled later by silent()). Using ${BASH_SOURCE[0]:-}
# safely defaults to empty string instead of erroring out.
set_std_mode() {
  if [ "${VERBOSE:-no}" = "yes" ]; then STD=""; else STD="silent"; fi
  if [[ "${DEV_MODE_TRACE:-false}" == "true" ]]; then
    set -x
    export PS4='+(${BASH_SOURCE[0]:-}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
  fi
}

color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

read -r -p "Enter your Anthropic API Key: " ANTHROPIC_API_KEY

msg_info "Installing Dependencies"
$STD apt install -y \
  git \
  unzip \
  zip \
  htop \
  nano \
  vim \
  tmux \
  screen \
  yq \
  tree \
  dnsutils \
  cron \
  logrotate \
  build-essential \
  make \
  cmake \
  pkg-config \
  autoconf \
  automake \
  libtool \
  python3 \
  python3-pip \
  python3-venv \
  python3-dev \
  libssl-dev \
  libffi-dev \
  libsqlite3-dev \
  zlib1g-dev \
  libreadline-dev \
  libbz2-dev \
  libncurses-dev \
  liblzma-dev \
  libxml2-dev \
  libxslt-dev \
  ripgrep \
  fd-find \
  fzf \
  bat \
  rsync \
  sqlite3 \
  postgresql-client \
  redis-tools
msg_ok "Installed Dependencies"

NODE_VERSION="22" NODE_MODULE="typescript,ts-node,eslint,prettier" setup_nodejs
GO_VERSION="latest" setup_go
setup_rust
USE_DOCKER_REPO=true setup_docker

msg_info "Installing Claude Code"
$STD bash -c "curl -fsSL https://claude.ai/install.sh | bash"
if [[ -f "/root/.local/bin/claude" ]]; then
  ln -sf /root/.local/bin/claude /usr/local/bin/claude
elif [[ -f "/root/.claude/bin/claude" ]]; then
  ln -sf /root/.claude/bin/claude /usr/local/bin/claude
fi
mkdir -p /root/.claude/skills
cat <<'EOF' >/root/.claude/settings.json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "allow": [
      "Bash(*)",
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "MultiEdit(*)",
      "WebFetch(*)",
      "WebSearch(*)",
      "TodoRead(*)",
      "TodoWrite(*)",
      "Grep(*)",
      "Glob(*)",
      "LS(*)",
      "Task(*)",
      "mcp__*"
    ]
  },
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
    "CLAUDE_CODE_MAX_OUTPUT_TOKENS": "64000",
    "MAX_THINKING_TOKENS": "31999"
  },
  "alwaysThinkingEnabled": true,
  "enableRemoteControl": true,
  "enabledPlugins": {
    "frontend-design@claude-code-plugins": true,
    "code-review@claude-code-plugins": true,
    "commit-commands@claude-code-plugins": true,
    "security-guidance@claude-code-plugins": true,
    "context7@claude-plugin-directory": true,
    "webapp-testing@anthropic-agent-skills": true,
    "superpowers@superpowers-marketplace": true
  }
}
EOF
mkdir -p /project
cat <<'EOF' >/project/CLAUDE.md
# Cagent Workspace

## Environment
- **OS**: Ubuntu 24.04 LXC container on Proxmox
- **Working directory**: /project
- **User**: root

## Available Tools
- **Languages**: Node.js 22 LTS, Python 3.12, Go (latest), Rust (latest)
- **Package managers**: npm, pip (use --break-system-packages), cargo, go install
- **Docker**: Docker Engine + Compose plugin, running and ready
- **Containers**: Watchtower (auto-updates), Code Server (port 8443)
- **Search tools**: ripgrep (rg), fd-find (fdfind), fzf
- **Databases**: PostgreSQL client (psql), Redis client (redis-cli), SQLite3

## AI Interfaces
- **claude**: Claude Code CLI — run in any terminal for full agentic coding
- **opencode**: OpenCode TUI — run in terminal for a rich TUI experience, or open Code Server and run \`opencode\` once to auto-install the VS Code chat panel extension. After that, interact directly from the Code Server sidebar without a terminal.

## Permissions
All tools are pre-approved — no permission prompts. Bash, Read, Write, Edit, WebFetch, WebSearch, Task, and MCP tools all run without confirmation.

## Agent Teams
Agent teams are enabled. You can spawn parallel teammates for complex tasks:
- Use agent teams for work that benefits from parallel exploration
- Use subagents (Task tool) for quick focused work that reports back
- tmux is installed for split-pane team visualization

## Remote Control
Remote control is enabled for all sessions. Every interactive session is automatically controllable
from claude.ai/code or the Claude mobile app. Use /remote-control or press spacebar to show QR code.

## Docker Usage
Docker compose files should go in /docker/<service-name>/docker-compose.yml.
Watchtower is already running and will auto-update any containers with `restart: unless-stopped`.
All Docker containers in this LXC need `security_opt: [apparmor=unconfined]`.

## Conventions
- Prefer creating files over printing long code blocks
- Use git for version control on all projects in /project/src/
- When installing Python packages, use: pip install --break-system-packages <package>
- Extended thinking is always on — use it for complex architectural decisions

## Installed Plugins
- **frontend-design**: Production-grade UI with distinctive aesthetics (auto-activates on frontend tasks)
- **code-review**: Multi-agent PR review with confidence scoring
- **commit-commands**: Git commit, push, and PR workflows (/commit, /push, /pr)
- **security-guidance**: Security warnings when editing sensitive files
- **context7**: Live, version-specific library docs lookup (reduces API hallucinations)
- **webapp-testing**: Playwright-based browser testing for UI verification and debugging
- **superpowers**: Development workflow framework — brainstorm → plan → implement with TDD
  - /superpowers:brainstorm — Refine ideas before coding
  - /superpowers:write-plan — Create implementation plans
  - /superpowers:execute-plan — Execute plans in batches via subagents
  - Auto-activating skills: test-driven-development, systematic-debugging, verification-before-completion
EOF
msg_ok "Installed Claude Code"

msg_info "Installing Claude Code Extensions"
$STD npx -y claude-plugins install @anthropics/claude-code-plugins/frontend-design
$STD npx -y claude-plugins install @anthropics/claude-code-plugins/code-review
$STD npx -y claude-plugins install @anthropics/claude-code-plugins/commit-commands
$STD npx -y claude-plugins install @anthropics/claude-code-plugins/security-guidance
$STD npx -y claude-plugins install @anthropics/claude-plugins-official/context7
$STD npx -y claude-plugins install @obra/superpowers-marketplace/superpowers
$STD git clone --depth 1 --filter=blob:none --sparse https://github.com/anthropics/skills.git /tmp/anthropic-skills
cd /tmp/anthropic-skills
$STD git sparse-checkout set skills/webapp-testing
cp -r /tmp/anthropic-skills/skills/webapp-testing /root/.claude/skills/webapp-testing
cd /root
rm -rf /tmp/anthropic-skills
$STD npx -y playwright install --with-deps chromium
msg_ok "Installed Claude Code Extensions"

msg_info "Installing OpenCode"
$STD npm install -g opencode-ai
mkdir -p /root/.config/opencode
cat <<EOF >/root/.config/opencode/opencode.json
{
  "model": "anthropic/claude-sonnet-4-6",
  "providers": {
    "anthropic": {
      "apiKey": "${ANTHROPIC_API_KEY}"
    }
  }
}
EOF
# Make the API key available system-wide so opencode and claude both pick it up
echo "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}" >>/etc/environment
msg_ok "Installed OpenCode"

msg_info "Configuring Shell Environment"
cat <<'EOF' >>/root/.bashrc

# ── Cagent Container ───────────────────────────────────────
export EDITOR=nano
export PATH="$HOME/.local/bin:$HOME/.claude/bin:$HOME/.cargo/bin:/usr/local/go/bin:$PATH"
# Aliases
alias ll="ls -lah --color=auto"
alias cls="clear"
alias ..="cd .."
alias ...="cd ../.."
alias gs="git status"
alias gl="git log --oneline -20"
alias dc="docker compose"
alias dps="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
# Always start in /project
cd /project 2>/dev/null || true
EOF
git config --global init.defaultBranch main
git config --global core.editor nano
git config --global pull.rebase false
msg_ok "Configured Shell Environment"

msg_info "Setting Up Docker Services"
CT_TZ=$(cat /etc/timezone 2>/dev/null || echo "UTC")
CODE_SERVER_PASS=$(openssl rand -base64 24 | tr -dc 'a-zA-Z0-9' | head -c 20)
mkdir -p /docker/watchtower /docker/code-server
cat <<EOF >/docker/watchtower/docker-compose.yml
services:
  watchtower:
    image: containrrr/watchtower
    container_name: watchtower
    restart: unless-stopped
    environment:
      TZ: ${CT_TZ}
      WATCHTOWER_CLEANUP: "true"
      WATCHTOWER_INCLUDE_STOPPED: "true"
      WATCHTOWER_SCHEDULE: "0 0 4 * * *"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    security_opt:
      - apparmor=unconfined
EOF
cat <<EOF >/docker/code-server/docker-compose.yml
services:
  code-server:
    image: lscr.io/linuxserver/code-server:latest
    container_name: code-server
    restart: unless-stopped
    environment:
      PUID: "0"
      PGID: "0"
      TZ: ${CT_TZ}
      PASSWORD: ${CODE_SERVER_PASS}
    volumes:
      - ./config:/config
      - /project:/config/workspace
    ports:
      - 8443:8443
    security_opt:
      - apparmor=unconfined
EOF
cat <<EOF >~/cagent.creds
Cagent Service Credentials
──────────────────────────
Code Server URL:  http://${LOCAL_IP}:8443
Code Server Pass: ${CODE_SERVER_PASS}
Anthropic API Key: ${ANTHROPIC_API_KEY}

Usage:
  Terminal:   claude (Claude Code CLI)
              opencode (OpenCode TUI)
  Code Server chat panel: open Code Server, run 'opencode' once in
              the terminal — it auto-installs the VS Code extension.
              After that, use the chat panel without a terminal.
EOF
cd /docker/watchtower && $STD docker compose up -d
cd /docker/code-server && $STD docker compose up -d
msg_ok "Set Up Docker Services"

motd_ssh
customize
cleanup_lxc
