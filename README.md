# ezXSSetup

Automated installation script for [ezXSS](https://github.com/ssl/ezXSS) on a fresh Ubuntu server using Docker.

## Prerequisites

- A fresh Ubuntu server (22.04 or later recommended)
- Root access
- A domain name pointed to the server's IP address

## Quick Start

```bash
git clone https://github.com/<your-username>/ezXSSetup.git
cd ezXSSetup
sudo bash install.sh
```

## What the Script Does

1. **Installs Docker** — Adds the official Docker repository and installs Docker Engine with Compose plugin
2. **Clones ezXSS** — Downloads the latest ezXSS release to `/opt/ezxss`
3. **Configures the environment** — Sets up `.env` with your domain, a randomly generated database password, SSL, and mail alert preferences
4. **Starts the containers** — Launches ezXSS and MySQL via `docker compose`

## Interactive Prompts

During installation, the script will ask for:

| Prompt | Description |
|---|---|
| Domain | The domain ezXSS will run on (e.g. `xss.example.com`) |
| SSL | Whether to auto-provision a Let's Encrypt certificate (default: yes) |
| Email alerts | Whether to enable email notifications (default: yes) |

## Post-Installation

Once the script finishes, open the setup URL shown in the output to create your admin account:

```
https://your-domain.com/manage/install
```

### Useful Commands

```bash
# View logs
docker compose -f /opt/ezxss/docker-compose.yml logs -f

# Check container status
docker compose -f /opt/ezxss/docker-compose.yml ps

# Stop ezXSS
docker compose -f /opt/ezxss/docker-compose.yml down

# Restart ezXSS
docker compose -f /opt/ezxss/docker-compose.yml up -d
```

## Disclaimer

This tool is intended for **authorized security testing and bug bounty programs only**. Always obtain proper authorization before testing for vulnerabilities. Misuse of this tool may violate laws and regulations.

## License

MIT
