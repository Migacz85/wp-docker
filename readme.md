# 🚀 WordPress Docker Stack with SSL and phpMyAdmin

This project automates the deployment of a WordPress website using Docker with self-signed SSL, phpMyAdmin, and persistent volumes.

---

## ✅ First-Time Setup

Set Config.config 
PRODUCTION_DOMAIN="portainer-eu.matrix-test.com"
PRODUCTION_IP="164.92.217.201"
LOCAL_DOMAIN="localhost"
WORDPRESS_IMAGE="wordpress:6.7.0-php8.2"

Run the deploy script:

```bash
./deploy.sh 
```

- Enter a name for your stack when prompted
- Select a WordPress image version from the list

### Available WordPress Images
The deployment includes support for multiple WordPress versions with different PHP versions:
- Latest stable release
- Specific WordPress versions (6.8, 6.7, etc.)
- PHP 8.x and 7.x variants

The script will:
1. Generate self-signed SSL certificates (On localhost )
2. Create `.env` with unique credentials and ports
3. Launch WordPress, MySQL, and phpMyAdmin using Docker Compose

After deployment, it will print URLs and passwords to access:
- WordPress (HTTP & HTTPS)
- phpMyAdmin
- Database credentials

---

## 🔁 Redeploy Core WordPress (Preserving Content)

Run:

```bash
./re-deploy.sh 
```

- Enter your stack name
- Select a WordPress image version from the list
- This will:
  - Reuse existing environment variables and volumes
  - Pull updated images if available
  - Restart containers with existing data
  - Allow switching WordPress versions while preserving content

---

## 🔐 Persistent Data

The following data is preserved between restarts:
- ✅ Plugins (inside `./wp-content/plugins`)
- ✅ Themes (inside `./wp-content/themes`)
- ✅ Uploads (inside `./wp-content/uploads`)
- ✅ MySQL database (inside `./db` directory)

---

## 🧼 Cleanup Everything

To remove all containers, volumes, and files:

```bash
docker compose --env-file .env-[your-stack-name] down -v
rm -rf db/ .env-[your-stack-name]
```

---

## 📁 Project Structure

```
.
├── deploy.sh          # First-time deployment (rm volumes && generate all new env vars)
├── re-deploy.sh       # Core-only redeploy (preserve content)
├── docker-compose.yml # Main Docker stack definition
├── docker-compose.override.yml # SSL and URL configuration
├── cert/              # Self-signed SSL certificates
├── wp-content/        # WordPress content directory
│   ├── plugins/       # WordPress plugins
│   ├── themes/        # WordPress themes
│   └── uploads/       # Media uploads
├── db/                # MySQL database files
└── .env-[stackname]   # Auto-generated env file
```

---

## ⚙️ Configuration

### SSL Certificates
- Self-signed certificates are automatically generated in `./cert/`
- You can replace these with your own certificates by:
  1. Place certificate in `./cert/localhost.pem`
  2. Place private key in `./cert/localhost-key.pem`

I generated them using mkcert:

```bash
mkcert 
```


### WordPress URLs
Configured in `docker-compose.override.yml`:
- `WORDPRESS_SITEURL`
- `WORDPRESS_HOME`

---

## 💬 Example Deployment

```bash
# First deployment
./deploy.sh --domain mysite.local --logs
# Enter stack name: mystack

# Redeploy
./re-deploy.sh --logs
# Enter stack name: mystack
```

---

## 📝 Notes

- Ports and passwords are randomized on first deploy
- Default WordPress version: 6.7.0 with PHP 8.2
- MySQL version: 10.6
- Supports multiple WordPress and PHP versions
- Easy version switching during redeployment


