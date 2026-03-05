read -p "Os: " os
read -p "Hostname: " hostname
read -p "Custom User: " user
read -p "Custom Password: " pass
read -p "SSH Port: " port
read -p "RAM (MB): " ram
read -p "CPU: " cpu
read -p "Disk (GB): " disk

P=$(shuf -i 2000-65000 -n1)
####################################
# Dockerfile template
####################################
rm Dockerfile
cat > Dockerfile <<EOF
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOSTNAME=$hostname

# -----------------------------
# Install Required Packages
# -----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    sudo \
    qemu-system-x86 \
    cloud-image-utils \
    openssh-client \
    htop \
    neovim \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------
# Create VM Directory
# -----------------------------
WORKDIR /workspace
RUN mkdir -p /vm/debian13

# -----------------------------
# Download Debian 13 QCOW2
# -----------------------------
RUN wget $os

# -----------------------------
# Cloud Init Config
# -----------------------------
RUN cat <<EOF > /vm/$hostname/user-data
#cloud-config
ssh_pwauth: true
disable_root: false

chpasswd:
  list: |
    root:root
    $user:$pass
  expire: false

users:
  - default
  - name: nn
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) ALL
EOF

RUN cat <<EOF > /vm/$hostname/meta-data
instance-id: $hostname
local-hostname: $hostname
EOF

RUN cloud-localds /vm/$hostname/seed.iso \
    /vm/$hostname/user-data \
    /vm/$hostname/meta-data

# -----------------------------
# Expose SSH Port
# -----------------------------
EXPOSE $P 22

# -----------------------------
# Smart Startup
# -----------------------------
CMD bash -c "\
TOTAL_RAM=\$(awk '/MemTotal/ {print int(\$2/1024)}' /proc/meminfo); \
VM_RAM=\$((TOTAL_RAM*70/100)); \
CPU_CORES=\$(nproc); \
echo \"Detected RAM: \$TOTAL_RAM MB\"; \
echo \"Allocating VM RAM: \$VM_RAM MB\"; \
echo \"Detected CPU Cores: \$CPU_CORES\"; \
qemu-system-x86_64 \
-m \$VM_RAM \
-smp \$CPU_CORES \
-drive file=/vm/$hostname/debian13.qcow2,format=qcow2 \
-drive file=/vm/$hostname/seed.iso,format=raw \
-net nic \
-net user,hostfwd=tcp::2222-:22 \
-nographic"
EOF

# ====================================================

selt os  
declare -A OS_OPTIONS=(
["Ubuntu22"]="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
["Ubuntu24"]="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
["Debian11"]="https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-generic-amd64.qcow2"
["Debian12"]="https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
["Debian13"]="https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2"
["Fedora40"]="https://download.fedoraproject.org/pub/fedora/linux/releases/40/Cloud/x86_64/images/Fedora-Cloud-Base-40-1.14.x86_64.qcow2"
["CentOS9"]="https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-latest.x86_64.qcow2"
)
