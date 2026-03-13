#!/bin/bash
# =============================================================================
# Part 1: Deploy HTML/CSS Application on Apache
# =============================================================================
set -e  # Exit immediately on any error

APP_DIR="/var/www/html/devops-site"

# Detect OS and set package manager + Apache service name
if [ -f /etc/debian_version ]; then
    PKG_MANAGER="apt"
    APACHE_PKG="apache2"
    APACHE_SERVICE="apache2"
    APACHE_CONF="/etc/apache2/sites-available/000-default.conf"
    WEB_USER="www-data"
    LOG_DIR="\${APACHE_LOG_DIR}"
else
    PKG_MANAGER="yum"
    APACHE_PKG="httpd"
    APACHE_SERVICE="httpd"
    APACHE_CONF="/etc/httpd/conf.d/devops-site.conf"
    WEB_USER="apache"
    LOG_DIR="/var/log/httpd"
fi

echo "=============================================="
echo " Apache HTML/CSS Deployment Script"
echo "=============================================="

# 1. Update system and install Apache
echo "[1/4] Installing Apache..."
if [ "$PKG_MANAGER" = "apt" ]; then
    sudo apt update -y
fi
sudo $PKG_MANAGER install $APACHE_PKG -y

# 2. Enable Apache and start service
echo "[2/4] Starting Apache..."
sudo systemctl enable $APACHE_SERVICE
sudo systemctl start $APACHE_SERVICE

# 3. Copy HTML application to Apache document root
echo "[3/4] Deploying HTML/CSS application..."
sudo mkdir -p "$APP_DIR"
sudo cp -r html-app/* "$APP_DIR/"
sudo chown -R $WEB_USER:$WEB_USER "$APP_DIR"
sudo chmod -R 755 "$APP_DIR"

# Update vhost to point to our app directory
sudo bash -c "cat > $APACHE_CONF" <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot $APP_DIR
    ErrorLog $LOG_DIR/error.log
    CustomLog $LOG_DIR/access.log combined
</VirtualHost>
EOF

# 4. Reload Apache to apply changes
echo "[4/4] Reloading Apache..."
sudo systemctl reload $APACHE_SERVICE

echo ""
echo "=============================================="
echo " Deployment complete!"
echo " Site is live at: http://$(hostname -I | awk '{print $1}')"
echo "=============================================="
