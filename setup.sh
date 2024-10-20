#!/bin/sh

apk update
apk add nano docker bc bash neofetch

rc-update add docker boot
service docker start

cat <<EOF > Dockerfile
FROM ubuntu:22.04

RUN apt-get update 
RUN apt-get install -y neofetch nano htop curl wget dialog openssh-server sudo gpg
RUN sudo sed -i 's/^#\\?\\s*PermitRootLogin\\s\\+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN wget -O /usr/bin/neofetch https://raw.githubusercontent.com/katy-the-kat/realinstallscript/refs/heads/main/neofetch.sh
RUN chmod +x /usr/bin/neofetch
RUN echo 'root:root' | chpasswd
RUN printf '#!/bin/sh\\nexit 0' > /usr/sbin/policy-rc.d
RUN apt-get install -y systemd systemd-sysv dbus dbus-user-session
RUN printf "systemctl start systemd-logind" >> /etc/profile

ENTRYPOINT ["/sbin/init"]
EOF

docker build -t utmp .

cat <<'EOF' > /usr/bin/heheantiminer
#!/bin/sh

CPU_THRESHOLD=110.0  # CPU usage in percentage
DURATION=0  # seconds

get_container_stats() {
    docker stats --format "{{.ID}} {{.CPUPerc}}" | sed 's/%//g'
}

monitor_containers() {
    declare -A containers_over_threshold

    get_container_stats | while read -r line; do
        container_id=$(echo "$line" | awk '{print $1}')
        cpu_usage=$(echo "$line" | awk '{print $2}')

        if ! [ "$cpu_usage" ] || ! [ "$cpu_usage" -eq "$cpu_usage" ] 2>/dev/null; then
            cpu_usage=$(printf "%.0f" "$cpu_usage")  # Convert to integer if needed
        fi

        if [ "$(echo "$cpu_usage >= $CPU_THRESHOLD" | bc)" -eq 1 ]; then
            # Increment the count for containers over threshold
            if [ "${containers_over_threshold[$container_id]}" ]; then
                containers_over_threshold[$container_id]=$((containers_over_threshold[$container_id] + 1))
            else
                containers_over_threshold[$container_id]=1
            fi

            # Remove the container if it exceeds the duration
            if [ "${containers_over_threshold[$container_id]}" -ge "$DURATION" ]; then
                echo "Removing container $container_id due to high CPU usage."
                docker rm -vf "$container_id"
                unset containers_over_threshold[$container_id]  # Reset the counter
            fi
        else
            # Reset the counter if below threshold
            unset containers_over_threshold[$container_id]
        fi
    done
}

monitor_containers
EOF

chmod +x /usr/bin/heheantiminer
nohup /usr/bin/heheantiminer > /dev/null 2>&1 &

rm /usr/bin/neofetch
wget -O /usr/bin/neofetch https://raw.githubusercontent.com/katy-the-kat/realinstallscript/refs/heads/main/flexingfr
chmod +x /usr/bin/neofetch

clear && echo done

