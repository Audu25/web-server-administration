#!/bin/bash
# =============================================================================
# Part 3: Deploy Node.js Application with Nginx Reverse Proxy
# =============================================================================
set -e

DOMAIN="nodeapp.local"
APP_SRC="$(pwd)/app"
APP_DEST="/var/www/nodeapp"
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
NODE_SERVICE="/etc/systemd/system/nodeapp.service"

echo "=============================================="
echo " Node.js + Nginx Reverse Proxy Setup"
echo " Domain: $DOMAIN"
echo "=============================================="

# 1. Install Node.js (via NodeSource) and Nginx
echo "[1/5] Installing Node.js and Nginx..."
sudo apt update -y

# Install Node.js 20.x
if ! command -v node &>/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
fi

# Install Nginx
if ! command -v nginx &>/dev/null; then
    sudo apt install -y nginx
fi

echo "  Node.js version: $(node -v)"
echo "  Nginx version:   $(nginx -v 2>&1)"

# 2. Deploy application files
echo "[2/5] Deploying application..."
sudo mkdir -p "$APP_DEST"
sudo cp -r "$APP_SRC"/* "$APP_DEST/"
sudo chown -R www-data:www-data "$APP_DEST"

# Install Node.js dependencies
cd "$APP_DEST"
sudo npm install --omit=dev
cd -

# 3. Create systemd service to keep Node.js running
echo "[3/5] Creating systemd service..."
sudo bash -c "cat > $NODE_SERVICE" <<EOF
[Unit]
Description=Node.js Application - $DOMAIN
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=$APP_DEST
ExecStart=/usr/bin/node $APP_DEST/server.js
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
sudo cp nginx/nodeapp.conf "$NGINX_CONF"

# Enable site
sudo ln -sf "$NGINX_CONF" "/etc/nginx/sites-enabled/$DOMAIN"
# Disable default Nginx site
sudo rm -f /etc/nginx/sites-enabled/default

# Add domain to /etc/hosts for local testing
if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "127.0.0.1   $DOMAIN www.$DOMAIN" | sudo tee -a /etc/hosts
fi

# Test config and reload Nginx
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl reload nginx

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
