# Web Server Administration

> Deploy and manage high-performance web servers using Apache and Nginx.

---

## Project Structure

```
web-server-administration/
├── 1-apache-html/          # Part 1: Static site on Apache
│   ├── html-app/
│   │   ├── index.html
│   │   └── style.css
│   └── setup.sh
│
├── 2-apache-vhost/         # Part 2: Apache VirtualHost
│   ├── html-app/
│   │   ├── index.html
│   │   └── style.css
│   ├── apache/
│   │   └── myapp.local.conf
│   └── setup.sh
│
└── 3-nodejs-nginx-proxy/   # Part 3: Node.js + Nginx Reverse Proxy
    ├── app/
    │   ├── server.js
    │   ├── package.json
    │   └── public/
    │       ├── index.html
    │       └── style.css
    ├── nginx/
    │   └── nodeapp.conf
    └── setup.sh
```

---

## Part 1 — Deploy HTML/CSS App on Apache

Deploys a static website to the Apache default document root.

**How it works:**
1. Installs Apache (`apt install apache2`)
2. Copies HTML/CSS files to `/var/www/html/devops-site/`
3. Updates the default VirtualHost to point to the app directory
4. Reloads Apache

**Deploy:**
```bash
cd 1-apache-html
chmod +x setup.sh
./setup.sh
```

**Access:** `http://<server-ip>`

---

## Part 2 — Deploy HTML/CSS App on Apache using VirtualHost

Hosts the site under a custom domain (`myapp.local`) using Apache VirtualHost, allowing multiple sites on one server.

**How it works:**
1. Creates `/var/www/myapp.local/html/` and copies the app
2. Installs a VirtualHost config at `/etc/apache2/sites-available/myapp.local.conf`
3. Enables the site with `a2ensite`
4. Adds `myapp.local` to `/etc/hosts` for local resolution
5. Reloads Apache

**Deploy:**
```bash
cd 2-apache-vhost
chmod +x setup.sh
./setup.sh
```

**Access:** `http://myapp.local`

> For remote server: add `<SERVER_IP>   myapp.local` to your local hosts file.

---

## Part 3 — Node.js App with Nginx Reverse Proxy

Runs an Express.js application on port 3000 and uses Nginx as a reverse proxy on port 80.

**Architecture:**
```
Client → Nginx (port 80) → Node.js / Express (port 3000)
```

**How it works:**
1. Installs Node.js 20.x and Nginx
2. Deploys the Express app to `/var/www/nodeapp/`
3. Creates a `systemd` service (`nodeapp`) to keep Node.js running
4. Configures Nginx to proxy `http://nodeapp.local` → `localhost:3000`
5. Enables and starts both services

**Deploy:**
```bash
cd 3-nodejs-nginx-proxy
chmod +x setup.sh
./setup.sh
```

**Access:** `http://nodeapp.local`

**API Endpoints:**
| Endpoint | Description |
|---|---|
| `GET /api/status` | App health check and uptime |
| `GET /api/info` | Server info (Node version, hostname, etc.) |

**Useful commands:**
```bash
sudo systemctl status nodeapp          # Check Node.js service
sudo systemctl status nginx            # Check Nginx
sudo journalctl -u nodeapp -f          # Stream Node.js logs
sudo tail -f /var/log/nginx/nodeapp.local_access.log
```

---

## Prerequisites

- Ubuntu/Debian Linux server (EC2, VM, or local)
- `sudo` privileges
- Internet access (for package installation)
