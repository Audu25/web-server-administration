#!/bin/bash
# =============================================================================
# Part 1: Deploy HTML/CSS Application on Apache
# =============================================================================
set -e  # Exit immediately on any error

APP_DIR="/var/www/html/devops-site"
APACHE_CONF="/etc/apache2/sites-available/000-default.conf"

echo "=============================================="
echo " Apache HTML/CSS Deployment Script"
echo "=============================================="

# 1. Update system and install Apache
echo "[1/4] Installing Apache..."
sudo apt update -y
sudo apt install apache2 -y

# 2. Enable Apache and start service
echo "[2/4] Starting Apache..."
sudo systemctl enable apache2
sudo systemctl start apache2

# 3. Copy HTML application to Apache document root
echo "[3/4] Deploying HTML/CSS application..."
sudo mkdir -p "$APP_DIR"
sudo cp -r html-app/* "$APP_DIR/"
sudo chown -R www-data:www-data "$APP_DIR"
sudo chmod -R 755 "$APP_DIR"

# Update default vhost to point to our app directory
sudo bash -c "cat > $APACHE_CONF" <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot $APP_DIR
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# 4. Reload Apache to apply changes
echo "[4/4] Reloading Apache..."
sudo systemctl reload apache2

echo ""
echo "=============================================="
echo " Deployment complete!"
echo " Site is live at: http://$(hostname -I | awk '{print $1}')"
echo "=============================================="
