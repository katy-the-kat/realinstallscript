apk add openssh-client fastfetch bash &

apk add openssh-server

sed -i 's/^#\?\s*PermitRootLogin\s\+.*/PermitRootLogin yes/' /etc/ssh/sshd_config

service ssh restart

