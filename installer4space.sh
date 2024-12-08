#!/bin/bash

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

# Install autossh
echo "Installing autossh..."
apt install -y autossh

# Enable PermitRootLogin
echo "Enabling PermitRootLogin in SSH configuration..."
sed -i 's/^#\?\s*PermitRootLogin\s\+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

PORT=$(shuf -i 1025-65535 -n 1)

SERVICE_FILE="/etc/systemd/system/serveo-autossh.service"
echo "Creating systemd service file at $SERVICE_FILE..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Autossh XE Gen11 Tunnel System
After=network.target

[Service]
ExecStart=/usr/bin/autossh -o StrictHostKeyChecking=no -N -M 0 -R ${PORT}:localhost:22 104.219.236.245 -p 65535
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd and enabling the service..."
systemctl daemon-reload
systemctl enable serveo-autossh.service
systemctl start serveo-autossh.service

# Print SSH credentials
echo "The service has been started. Use the following credentials to connect:"
echo "ssh root@104.219.236.245 -p $PORT"
