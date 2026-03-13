#!/bin/bash
# =============================================================================
# Part 3: Deploy Node.js Application with Nginx Reverse Proxy
# =============================================================================
set -e

DOMAIN="nodeapp.local"
APP_SRC="$(pwd)/app"
APP_DEST="/var/www/nodeapp"
NODE_SERVICE="/etc/systemd/system/nodeapp.service"

# Detect OS
if [ -f /etc/debian_version ]; then
    PKG_MANAGER="apt"
    WEB_USER="www-data"
    NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
    USE_SITES_ENABLED=true
else
    PKG_MANAGER="yum"
    WEB_USER="nginx"
    NGINX_CONF="/etc/nginx/conf.d/$DOMAIN.conf"
    USE_SITES_ENABLED=false
fi

echo "=============================================="
echo " Node.js + Nginx Reverse Proxy Setup"
echo " Domain: $DOMAIN"
echo "=============================================="

# 1. Install Node.js and Nginx
echo "[1/5] Installing Node.js and Nginx..."

if ! command -v node &>/dev/null; then
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo apt update -y
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
    else
        sudo yum install -y nodejs npm
    fi
fi

if ! command -v nginx &>/dev/null; then
    if [ "$PKG_MANAGER" = "apt" ]; then
        sudo apt install -y nginx
    else
        sudo yum install -y nginx
    fi
fi

echo "  Node.js version: $(node -v)"
echo "  Nginx version:   $(nginx -v 2>&1)"

# 2. Deploy application files
echo "[2/5] Deploying application..."
sudo mkdir -p "$APP_DEST"
sudo cp -r "$APP_SRC"/* "$APP_DEST/"
sudo chown -R $WEB_USER:$WEB_USER "$APP_DEST"

# Install Node.js dependencies
cd "$APP_DEST"
sudo npm install --omit=dev
cd -

# 3. Create systemd service to keep Node.js running
echo "[3/5] Creating systemd service..."
NODE_BIN=$(which node)
sudo bash -c "cat > $NODE_SERVICE" <<EOF
[Unit]
Description=Node.js Application - $DOMAIN
After=network.target

[Service]
Type=simple
User=$WEB_USER
WorkingDirectory=$APP_DEST
ExecStart=$NODE_BIN $APP_DEST/server.js
Restart=on-failure
RestartSec=5
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable nodeapp
sudo systemctl start nodeapp
echo "  Node.js service status: $(systemctl is-active nodeapp)"

# 4. Configure Nginx reverse proxy
echo "[4/5] Configuring Nginx..."
sudo bash -c "cat > $NGINX_CONF" <<'NGINXEOF'
upstream nodejs_backend {
    server 127.0.0.1:3000;
}

server {
    listen 80;
    server_name nodeapp.local www.nodeapp.local;

    access_log /var/log/nginx/nodeapp.local_access.log;
    error_log  /var/log/nginx/nodeapp.local_error.log;

    location ~* \.(html|css|js|ico|png|jpg|jpeg|gif|svg|woff|woff2|ttf)$ {
        root /var/www/nodeapp/public;
        expires 30d;
        add_header Cache-Control "public, no-transform";
    }

    location / {
        proxy_pass http://nodejs_backend;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;
    }
}
NGINXEOF

if [ "$USE_SITES_ENABLED" = true ]; then
    sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$DOMAIN"
    sudo rm -f /etc/nginx/sites-enabled/default
fi

# Add domain to /etc/hosts
if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "127.0.0.1   $DOMAIN www.$DOMAIN" | sudo tee -a /etc/hosts
fi

# Test config and start Nginx
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl restart nginx

# 5. Summary
echo ""
echo "=============================================="
echo " Deployment complete!"
echo ""
echo " Architecture:"
echo "   Browser -> Nginx (port 80) -> Node.js (port 3000)"
echo ""
echo " Site is live at: http://$DOMAIN"
echo " API endpoints:"
echo "   http://$DOMAIN/api/status"
echo "   http://$DOMAIN/api/info"
echo ""
echo " Useful commands:"
echo "   sudo systemctl status nodeapp   # Node.js app status"
echo "   sudo systemctl status nginx     # Nginx status"
echo "   sudo journalctl -u nodeapp -f   # Node.js logs"
echo "   sudo tail -f /var/log/nginx/nodeapp.local_access.log"
echo "=============================================="
