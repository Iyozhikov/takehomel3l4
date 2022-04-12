#!/bin/bash
# Install required software
apt update && apt upgrade -y && \
apt install -y openssh-server python3.8 && \
systemctl restart ssh

# Write service code to file system
cat << EOF > /usr/local/bin/takehomel3l4.py
${server_code}
EOF

# Write service shell starter to file system
cat << EOF > /usr/local/bin/takehomel3l4.sh
${server_starter}
EOF

# Write service systemd unit to file system
cat << EOF > /etc/systemd/system/takehomel3l4.service
${server_unit}
EOF


# Set executable bit
chmod +x /usr/local/bin/takehomel3l4.py
chmod +x /usr/local/bin/takehomel3l4.sh

# Systemd
systemctl daemon-relaod
# stop old service
systemctl stop guardian.service
systemctl disable guardian.service
# add new service
systemctl enable takehomel3l4.service
systemctl start takehomel3l4.service
