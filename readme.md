Generated and configured by Marcin

# 🚀 WordPress Docker Stack on Digital Ocean– Quick Start Guide

This project automates the deployment of a WordPress website using Docker with SSL, phpMyAdmin, and persistent volumes.

---

## ✅ First-Time Setup

Run the deploy script:

./deploy.sh

- Enter a name for your stack when prompted.
- It will:
  - Create `.env-[stackname]` with unique credentials and ports.
  - Launch WordPress, MySQL, and phpMyAdmin using Docker Compose.

After it's done, it will print URLs and passwords to access:

- WordPress
- WordPress (HTTPS)
- phpMyAdmin

---

## 🔁 Redeploy Core WordPress (Preserving Content)

Run:

./redeploy.sh

- Enter your stack name.
- This will:
  - Delete only WordPress core files (`wp-admin`, `wp-includes`, `.php` files).
  - Keep your uploads, plugins, themes, and database.
  - Rebuild WordPress container cleanly.

---

## 🔐 What Gets Saved

Persistent between restarts:

- ✅ Plugins (inside `./data/wp-content/plugins`)
- ✅ Themes (inside `./data/wp-content/themes`)
- ✅ Uploads (inside `./data/wp-content/uploads`)
- ✅ MySQL database (inside Docker volume `db`)

---

## 🧼 Cleanup Everything

To remove all containers, volumes, and files:

docker compose --env-file .env-[your-stack-name] down -v
rm -rf data/ .env-[your-stack-name]

---

## 📁 Project Structure

.
├── deploy.sh          # First-time deployment
├── redeploy.sh        # Core-only redeploy (preserve content)
├── docker-compose.yml # Docker stack definition
├── data/              # Mounted WordPress data (plugins, themes, uploads)
└── .env-[stackname]   # Auto-generated env file

---

## 📝 Notes

- SSL certs must exist at:
  - `/etc/letsencrypt/live/portainer-eu.matrix-test.com/fullchain.pem`
  - `/etc/letsencrypt/live/portainer-eu.matrix-test.com/privkey.pem`
- Ports and passwords are randomized on first deploy.

---

## 💬 Example

./deploy.sh
# Enter stack name: mystack

./redeploy.sh
# Enter stack name: mystack


