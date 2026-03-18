# Linux Server Bootstrap

A beginner DevOps and System Engineering project that automates the setup of a fresh Ubuntu server.

---

## Features

- Updates Ubuntu packages
- Creates a new sudo user
- Installs Docker
- Configures UFW firewall
- Installs and configures Nginx
- Deploys a simple Dockerised app
- Installs basic monitoring tools
- Provides a reset script to safely reverse the setup

---

## Project Structure

```bash
linux-server-bootstrap/
├── app/
│   ├── Dockerfile
│   └── index.html
├── nginx/
│   └── default.conf
├── bootstrap.sh
├── reset.sh
├── README.md
└── .gitignore
