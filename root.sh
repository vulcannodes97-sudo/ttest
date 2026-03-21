#!/bin/bash

# ===== CONFIG =====
ROOT_PASS="1234"

echo "Starting setup..."

# 1. Root password set
echo "Setting root password..."
echo "root:$ROOT_PASS" | chpasswd

# 2. SSH config update
echo "Configuring SSH..."

SSH_FILE="/etc/ssh/sshd_config"

# Backup config
cp $SSH_FILE $SSH_FILE.bak

# Enable root login
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' $SSH_FILE

# Enable password authentication
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' $SSH_FILE

# 3. Restart SSH service
echo "Restarting SSH service..."
systemctl restart ssh || systemctl restart sshd

# 4. Done
echo "================================="
echo " Root login enabled"
echo " Password set to: $ROOT_PASS"
echo "================================="
