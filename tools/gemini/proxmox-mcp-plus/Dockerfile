# Stage 1: Builder
FROM python:3.11-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Download and extract the repository
ARG COMMIT_SHA=main
RUN curl -L "https://github.com/RekklesNA/ProxmoxMCP-Plus/archive/${COMMIT_SHA}.tar.gz" -o repo.tar.gz \
    && tar -xzf repo.tar.gz --strip-components=1 \
    && rm repo.tar.gz

# Create virtual environment
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# Install Python dependencies
RUN pip install --no-cache-dir mcp proxmoxer requests uv

# Install the package
RUN pip install .

# Stage 2: Runner
FROM python:3.11-slim AS runner

WORKDIR /app

# Copy virtual environment from builder
COPY --from=builder /opt/venv /opt/venv

# Set environment variables
ENV PATH="/opt/venv/bin:$PATH"
ENV PROXMOX_MCP_CONFIG="/app/proxmox-config/config.json"

# Default command for Gemini CLI (stdio mode)
CMD ["python", "-m", "proxmox_mcp.server"]