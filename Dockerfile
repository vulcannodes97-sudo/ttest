FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOSTNAME=Nobita

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
# Install code-server
# -----------------------------
RUN curl -fsSL https://code-server.dev/install.sh | sh

# -----------------------------
# Create VM Directory
# -----------------------------
WORKDIR /workspace
RUN mkdir -p /vm/debian13

# -----------------------------
# Download Debian 13 QCOW2
# -----------------------------
RUN wget https://cloud.debian.org/images/cloud/trixie/daily/latest/debian-13-generic-amd64-daily.qcow2 \
    -O /vm/debian13/debian13.qcow2

# -----------------------------
# Proper Cloud-Init Config (ROOT + NN WORKING)
# -----------------------------
RUN cat <<EOF > /vm/debian13/user-data
#cloud-config
ssh_pwauth: true
disable_root: false

chpasswd:
  list: |
    root:root
    nn:nn
  expire: false

users:
  - default
  - name: nn
    groups: sudo
    shell: /bin/bash
    sudo: ALL=(ALL) ALL
EOF

RUN cat <<EOF > /vm/debian13/meta-data
instance-id: debian13
local-hostname: debian13
EOF

RUN cloud-localds /vm/debian13/seed.iso \
    /vm/debian13/user-data \
    /vm/debian13/meta-data

# -----------------------------
# Expose Ports
# -----------------------------
EXPOSE 7860 2222

# -----------------------------
# Smart Startup (Auto RAM + CPU)
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
-drive file=/vm/debian13/debian13.qcow2,format=qcow2 \
-drive file=/vm/debian13/seed.iso,format=raw \
-net nic \
-net user,hostfwd=tcp::2222-:22 \
-nographic & \
code-server --bind-addr 0.0.0.0:7860 --auth none"
