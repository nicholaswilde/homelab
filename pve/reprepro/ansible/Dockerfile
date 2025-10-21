# Use the arm64v8 version of Debian for our ARM image
ARG BUILD_ARCH=amd64
# FROM ${BUILD_ARCH}/debian:bullseye
# FROM ${BUILD_ARCH}/python:bullseye
FROM ${BUILD_ARCH}/python:slim-bullseye

# Install SSH and sudo
RUN apt-get update \
    && apt-get install -y openssh-server sudo python3 \
    && rm -rf /var/lib/apt/lists/*

# Create an ansible user
RUN useradd -m -s /bin/bash ansible \
    && echo "ansible:ansible" | chpasswd \
    && adduser ansible sudo \
    && echo "ansible ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Allow SSH login
RUN mkdir /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
