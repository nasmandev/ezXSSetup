#!/bin/bash
set -euo pipefail

# ============================================================
# ezXSS Docker Installer for Ubuntu
# Installs Docker, clones ezXSS, configures and starts it
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[+]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; exit 1; }

# --- Pre-flight checks -----------------------------------------------

if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root (use sudo)"
fi

# --- Gather user input ------------------------------------------------

read -rp "Enter the domain for ezXSS (e.g. xss.example.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    error "Domain cannot be empty"
fi

DB_PASSWORD=$(openssl rand -base64 24)
log "Generated random database password"

read -rp "Enable automatic SSL certificate via Let's Encrypt? (y/n) [y]: " SSL_CHOICE
SSL_CHOICE=${SSL_CHOICE:-y}

if [[ "$SSL_CHOICE" =~ ^[Yy]$ ]]; then
    AUTO_SSL="true"
    HTTP_MODE="false"
else
    AUTO_SSL="false"
    HTTP_MODE="true"
    warn "SSL disabled — ezXSS will run in HTTP-only mode"
fi

read -rp "Enable email alerts? (y/n) [y]: " MAIL_CHOICE
MAIL_CHOICE=${MAIL_CHOICE:-y}
[[ "$MAIL_CHOICE" =~ ^[Yy]$ ]] && MAIL_ALERTS="true" || MAIL_ALERTS="false"

# --- Install Docker ---------------------------------------------------

if command -v docker &>/dev/null; then
    log "Docker is already installed ($(docker --version))"
else
    log "Installing Docker..."
    apt-get update -y
    apt-get install -y ca-certificates curl gnupg

    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    systemctl enable --now docker
    log "Docker installed successfully"
fi

# --- Clone ezXSS -----------------------------------------------------

INSTALL_DIR="/opt/ezxss"

if [[ -d "$INSTALL_DIR" ]]; then
    warn "$INSTALL_DIR already exists — pulling latest changes"
    git -C "$INSTALL_DIR" pull
else
    log "Cloning ezXSS to $INSTALL_DIR..."
    apt-get install -y git
    git clone https://github.com/ssl/ezXSS.git "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# --- Configure .env ---------------------------------------------------

log "Creating .env configuration..."
cp .env.example .env

sed -i "s|^dbPassword=.*|dbPassword=${DB_PASSWORD}|" .env
sed -i "s|^domain=.*|domain=${DOMAIN}|" .env
sed -i "s|^autoInstallCertificate=.*|autoInstallCertificate=${AUTO_SSL}|" .env
sed -i "s|^httpmode=.*|httpmode=${HTTP_MODE}|" .env
sed -i "s|^useMailAlerts=.*|useMailAlerts=${MAIL_ALERTS}|" .env

# --- Start containers -------------------------------------------------

log "Starting ezXSS containers..."
docker compose up -d

# --- Wait for startup -------------------------------------------------

log "Waiting for ezXSS to become ready..."
sleep 10

if docker compose ps | grep -q "Up"; then
    log "Containers are running"
else
    warn "Containers may not be fully up yet — check with: docker compose -f $INSTALL_DIR/docker-compose.yml ps"
fi

# --- Done -------------------------------------------------------------

echo ""
echo "============================================================"
echo -e "${GREEN} ezXSS installation complete!${NC}"
echo "============================================================"
echo ""
echo "  Domain:       $DOMAIN"
echo "  Install dir:  $INSTALL_DIR"
echo "  DB password:  $DB_PASSWORD"
echo ""
if [[ "$AUTO_SSL" == "true" ]]; then
    echo "  Setup URL:    https://${DOMAIN}/manage/install"
else
    echo "  Setup URL:    http://${DOMAIN}/manage/install"
fi
echo ""
echo "  Open the setup URL to create your admin account."
echo ""
echo "  Useful commands:"
echo "    docker compose -f $INSTALL_DIR/docker-compose.yml logs -f"
echo "    docker compose -f $INSTALL_DIR/docker-compose.yml ps"
echo "    docker compose -f $INSTALL_DIR/docker-compose.yml down"
echo ""
echo "  IMPORTANT: Save the database password shown above!"
echo "============================================================"
