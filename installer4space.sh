#!/bin/bash

apk add openssh-server
apk add openssh-client fastfetch &

sed -i 's/^#\?\s*PermitRootLogin\s\+.*/PermitRootLogin yes/' /etc/ssh/sshd_config

service ssh restart

