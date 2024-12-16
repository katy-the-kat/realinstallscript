#!/bin/bash

# Usage: wget https://raw.githubusercontent.com/katy-the-kat/realinstallscript/refs/heads/main/installer4space.sh && bash installer4space.sh

touch /ports.txt
echo '#!/bin/bash

PORTS_FILE="/ports.txt"

add_port() {
    local local_port=$1
    if [[ -z "$local_port" ]]; then
        echo "Please provide a local port to forward."
        exit 1
    fi
    
    if [[ "$local_port" == "22" ]]; then
        echo "Port 22 cannot be added."
        exit 1
    fi
    
    if grep -q ":${local_port}$" "$PORTS_FILE"; then
        echo "Port ${local_port} is already forwarded."
        exit 1
    fi
    
    local random_port
    random_port=$(shuf -i 1-65534 -n 1)
    
    while [[ "$random_port" -eq 22 ]]; do
        random_port=$(shuf -i 1-65534 -n 1)
    done
    
    nohup ssh -o StrictHostKeyChecking=no -N -R ${random_port}:localhost:${local_port} root@213.191.216.34 -p 65535 &
    ssh_pid=$!
    
    echo "${random_port}:${local_port}" >> $PORTS_FILE
    
    echo "${local_port} is now on 213.191.216.34:${random_port}"
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
    
    pkill -f "nohup ssh -o StrictHostKeyChecking=no -f -N -R ${random_port}:localhost:${local_port} root@213.191.216.34 -p 65535"
    
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
        
        nohup ssh -o StrictHostKeyChecking=no -N -R ${random_port}:localhost:${local_port} root@213.191.216.34 -p 65535 &
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
        echo "Local port ${local_port} -> Public port ${random_port} (213.191.216.34)"
    done < $PORTS_FILE
}

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

echo "Enabling PermitRootLogin in SSH configuration..."
sed -i 's/^#\?\s*PermitRootLogin\s\+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
systemctl restart sshd



