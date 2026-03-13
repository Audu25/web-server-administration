#!/bin/bash
# =============================================================================
# Part 2: Deploy HTML/CSS Application on Apache using VirtualHost
# =============================================================================
set -e

DOMAIN="myapp.local"
APP_DIR="/var/www/$DOMAIN/html"
VHOST_CONF="/etc/apache2/sites-available/$DOMAIN.conf"

echo "=============================================="
echo " Apache VirtualHost Deployment Script"
echo " Domain: $DOMAIN"
echo "=============================================="

# 1. Install Apache if not already installed
echo "[1/6] Installing Apache..."
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl enable apache2
sudo systemctl start apache2

# 2. Create document root and copy app files
echo "[2/6] Creating document root..."
sudo mkdir -p "$APP_DIR"
sudo cp -r html-app/* "$APP_DIR/"
sudo chown -R www-data:www-data "/var/www/$DOMAIN"
sudo chmod -R 755 "/var/www/$DOMAIN"

# 3. Copy VirtualHost configuration
echo "[3/6] Installing VirtualHost configuration..."
sudo cp apache/$DOMAIN.conf "$VHOST_CONF"

# 4. Enable the new site and disable the default
echo "[4/6] Enabling site..."
sudo a2ensite "$DOMAIN.conf"
sudo a2dissite 000-default.conf  # optional: disable default site

# 5. Add domain to /etc/hosts (for local testing)
echo "[5/6] Configuring local DNS (hosts file)..."
if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "127.0.0.1   $DOMAIN www.$DOMAIN" | sudo tee -a /etc/hosts
    echo "  Added $DOMAIN to /etc/hosts"
else
    echo "  $DOMAIN already in /etc/hosts, skipping."
fi

# 6. Test config and reload Apache
echo "[6/6] Testing Apache config and reloading..."
sudo apache2ctl configtest
sudo systemctl reload apache2

echo ""
echo "=============================================="
echo " VirtualHost deployment complete!"
echo " Site is live at: http://$DOMAIN"
echo ""
echo " If testing remotely, add this to your local"
echo " /etc/hosts (or C:\\Windows\\System32\\drivers\\etc\\hosts):"
echo "   <SERVER_IP>   $DOMAIN www.$DOMAIN"
echo "=============================================="
