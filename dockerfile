cat <<EOF > Dockerfile
FROM ubuntu:22.04

RUN apt-get update 
RUN apt-get install -y nano htop wget dialog openssh-server openssh-client sudo
RUN wget -O /usr/bin/neofetch https://raw.githubusercontent.com/katy-the-kat/realinstallscript/refs/heads/main/neofetch.sh
RUN chmod +x /usr/bin/neofetch
RUN wget -O /usr/bin/port https://raw.githubusercontent.com/katy-the-kat/portip/refs/heads/main/pubb.sh
RUN chmod +x /usr/bin/port
RUN sed -i 's/^#\?\s*PermitRootLogin\s\+.*/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'root:root' | chpasswd
RUN printf '#!/bin/sh\nexit 0' > /usr/sbin/policy-rc.d
RUN apt-get install -y systemd systemd-sysv dbus dbus-user-session
RUN printf "systemctl start systemd-logind" >> /etc/profile

ENTRYPOINT ["/sbin/init"]
EOF

docker build -t utmp .