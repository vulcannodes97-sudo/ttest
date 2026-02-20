FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt upgrade -y && \
    apt install -y \
    openssh-server \
    cockpit \
    cockpit-machines \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    sudo && \
    apt clean

# SSH setup
RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#Port 22/Port 2222/' /etc/ssh/sshd_config

# Allow root in cockpit
RUN if [ -f /etc/cockpit/disallowed-users ]; then \
    sed -i '/root/d' /etc/cockpit/disallowed-users; \
    fi

# Expose ports
EXPOSE 2222
EXPOSE 9090

CMD ["/usr/sbin/sshd", "-D"]
