#!/bin/bash
# =============================================================================
# Part 2: Deploy HTML/CSS Application on Apache using VirtualHost
# =============================================================================
set -e

DOMAIN="myapp.local"
APP_DIR="/var/www/$DOMAIN/html"

# Detect OS
if [ -f /etc/debian_version ]; then
    PKG_MANAGER="apt"
    APACHE_PKG="apache2"
    APACHE_SERVICE="apache2"
    VHOST_CONF="/etc/apache2/sites-available/$DOMAIN.conf"
    WEB_USER="www-data"
    LOG_DIR="\${APACHE_LOG_DIR}"
    USE_A2ENSITE=true
else
    PKG_MANAGER="yum"
    APACHE_PKG="httpd"
    APACHE_SERVICE="httpd"
    VHOST_CONF="/etc/httpd/conf.d/$DOMAIN.conf"
    WEB_USER="apache"
    LOG_DIR="/var/log/httpd"
    USE_A2ENSITE=false
fi

echo "=============================================="
echo " Apache VirtualHost Deployment Script"
echo " Domain: $DOMAIN"
echo "=============================================="

# 1. Install Apache if not already installed
echo "[1/6] Installing Apache..."
if [ "$PKG_MANAGER" = "apt" ]; then
    sudo apt update -y
fi
sudo $PKG_MANAGER install $APACHE_PKG -y
sudo systemctl enable $APACHE_SERVICE
sudo systemctl start $APACHE_SERVICE

# 2. Create document root and copy app files
echo "[2/6] Creating document root..."
sudo mkdir -p "$APP_DIR"
sudo cp -r html-app/* "$APP_DIR/"
sudo chown -R $WEB_USER:$WEB_USER "/var/www/$DOMAIN"
sudo chmod -R 755 "/var/www/$DOMAIN"

# 3. Install VirtualHost configuration
echo "[3/6] Installing VirtualHost configuration..."
sudo bash -c "cat > $VHOST_CONF" <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN
    ServerAlias www.$DOMAIN
    DocumentRoot $APP_DIR

    <Directory $APP_DIR>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog $LOG_DIR/${DOMAIN}_error.log
    CustomLog $LOG_DIR/${DOMAIN}_access.log combined
</VirtualHost>
EOF

# 4. Enable site (Ubuntu only)
echo "[4/6] Enabling site..."
if [ "$USE_A2ENSITE" = true ]; then
    sudo a2ensite "$DOMAIN.conf"
    sudo a2dissite 000-default.conf
else
    echo "  Amazon Linux: VirtualHost conf placed directly in /etc/httpd/conf.d/, no a2ensite needed."
fi

# 5. Add domain to /etc/hosts
echo "[5/6] Configuring local DNS (hosts file)..."
if ! grep -q "$DOMAIN" /etc/hosts; then
    echo "127.0.0.1   $DOMAIN www.$DOMAIN" | sudo tee -a /etc/hosts
    echo "  Added $DOMAIN to /etc/hosts"
else
    echo "  $DOMAIN already in /etc/hosts, skipping."
fi

# 6. Test config and reload Apache
echo "[6/6] Testing Apache config and reloading..."
sudo httpd -t 2>/dev/null || sudo apache2ctl configtest
sudo systemctl reload $APACHE_SERVICE

echo ""
echo "=============================================="
echo " VirtualHost deployment complete!"
echo " Site is live at: http://$DOMAIN"
echo ""
echo " If testing remotely, add this to your local"
echo " /etc/hosts (or C:\\Windows\\System32\\drivers\\etc\\hosts):"
echo "   <SERVER_IP>   $DOMAIN www.$DOMAIN"
echo "=============================================="
