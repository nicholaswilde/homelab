# Dockerfile to build Neovim for different architectures
ARG BASE_IMAGE=ubuntu:jammy
FROM ${BASE_IMAGE}

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    curl \
    git \
    jq \
    gettext \
    unzip \
    ninja-build && \
    rm -rf /var/lib/apt/lists/*

# Copy the entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set the working directory
WORKDIR /build

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]

