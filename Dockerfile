FROM ubuntu:22.04

ENV container docker
ENV DEBIAN_FRONTEND=noninteractive

# Update & upgrade
RUN apt update && apt upgrade -y

# Install Cockpit
RUN apt install -y cockpit && \
    systemctl enable cockpit.socket

# Install KVM & libvirt stack
RUN apt install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager && \
    systemctl enable libvirtd

# Install cockpit-machines
RUN apt install -y cockpit-machines

# Allow root in cockpit
RUN if [ -f /etc/cockpit/disallowed-users ]; then \
    sed -i '/root/d' /etc/cockpit/disallowed-users; \
    fi

# Add root to libvirt & kvm groups
RUN usermod -aG libvirt,kvm root

EXPOSE 9090

STOPSIGNAL SIGRTMIN+3

CMD ["/sbin/init"]
