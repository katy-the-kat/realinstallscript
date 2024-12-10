#!/bin/bash

# Usage: wget https://raw.githubusercontent.com/katy-the-kat/realinstallscript/refs/heads/main/installer4space.sh && bash installer4space.sh

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

echo '#!/bin/bash

PORTS_FILE="/ports.info.txt"

add_port() {
    local local_port=$1
    if [[ -z "$local_port" ]]; then
        echo "Please provide a local port to forward."
        exit 1
    fi
    
    local random_port
    random_port=$(shuf -i 1-65535 -n 1)
    
    ssh -o StrictHostKeyChecking=no -f -N -R ${random_port}:localhost:${local_port} root@185.233.106.156 -p 65535 > /dev/null &
    ssh_pid=$!
    
    echo "${random_port}:${local_port}" >> $PORTS_FILE
    
    echo "${local_port} is now on 185.233.106.156:${random_port}"
}

remove_port() {
    local local_port=$1
    if [[ -z "$local_port" ]]; then
        echo "Please provide a local port to remove."
        exit 1
    fi
    
    random_port=$(grep ":${local_port}$" $PORTS_FILE | cut -d':' -f1)
    
    if [[ -z "$random_port" ]]; then
        echo "Port ${local_port} not found."
        exit 1
    fi
    
    pkill -f "ssh -o StrictHostKeyChecking=no -f -N -R ${random_port}:localhost:${local_port} root@185.233.106.156 -p 65535" > /dev/null
    
    sed -i "/${random_port}:${local_port}/d" $PORTS_FILE > /dev/null
    
    echo "Port ${local_port} has been removed."
}

refresh_ports() {
    if [[ ! -f "$PORTS_FILE" ]]; then
        echo "No ports to refresh."
        exit 1
    fi
    
    while IFS= read -r line; do
        random_port=$(echo $line | cut -d':' -f1)
        local_port=$(echo $line | cut -d':' -f2)
        
        ssh -o StrictHostKeyChecking=no -f -N -R ${random_port}:localhost:${local_port} root@185.233.106.156 -p 65535 > /dev/null &
    done < $PORTS_FILE
    
    echo "Ports have been successfully restarted."
}

list_ports() {
    if [[ ! -f "$PORTS_FILE" ]]; then
        echo "No ports to list."
        exit 1
    fi
    
    echo "Current port mappings:"
    while IFS= read -r line; do
        random_port=$(echo $line | cut -d':' -f1)
        local_port=$(echo $line | cut -d':' -f2)
        echo "Local port ${local_port} -> Public port ${random_port} (185.233.106.156)"
    done < $PORTS_FILE
}

# Main function to parse the input commands
case "$1" in
    add)
        add_port "$2"
        ;;
    remove)
        remove_port "$2"
        ;;
    refresh)
        refresh_ports
        ;;
    list)
        list_ports
        ;;
    *)
        echo "Usage: $0 {add|remove|refresh|list} [port]"
        exit 1
        ;;
esac
' > /usr/bin/port

chmod +x /usr/bin/port

# Install autossh
echo "Installing autossh..."
apt install -y autossh

# Enable PermitRootLogin
echo "Enabling PermitRootLogin in SSH configuration..."
sed -i 's/^#\?\s*PermitRootLogin\s\+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd

PORT=$(shuf -i 1-65535 -n 1)

SERVICE_FILE="/etc/systemd/system/serveo-autossh.service"
echo "Creating systemd service file at $SERVICE_FILE..."
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Autossh XE Gen11 Tunnel System
After=network.target

[Service]
ExecStart=/usr/bin/autossh -o StrictHostKeyChecking=no -N -M 0 -R ${PORT}:localhost:22 root@185.233.106.156 -p 65535
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
echo "ssh root@185.233.106.156 -p $PORT"
