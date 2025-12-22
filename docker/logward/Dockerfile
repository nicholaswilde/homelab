# Stage 1: Build Fluent Bit
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y \
    build-essential cmake make curl flex bison \
    libssl-dev libsystemd-dev zlib1g-dev \
    libyaml-dev pkg-config libsasl2-dev

ARG VERSION=3.2.2
RUN curl -L https://github.com/fluent/fluent-bit/archive/v${VERSION}.tar.gz -o fb.tar.gz \
    && tar -xf fb.tar.gz

RUN cd fluent-bit-${VERSION}/build \
    && cmake -DFLB_JEMALLOC=OFF -DFLB_RELEASE=ON -DFLB_CONFIG_YAML=ON .. \
    && make -j$(nproc)

# Stage 2: Runtime Image (The fix is here)
FROM debian:bookworm-slim

# Install the RUNTIME versions of the libraries we compiled against
RUN apt-get update && apt-get install -y \
    libssl3 \
    libsystemd0 \
    zlib1g \
    libyaml-0-2 \
    libsasl2-2 \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /fluent-bit/etc /fluent-bit/log

COPY --from=builder /fluent-bit-3.2.2/build/bin/fluent-bit /usr/local/bin/fluent-bit

# Configuration files (Fixing the source path to include the versioned folder)
COPY --from=builder /fluent-bit-3.2.2/conf/fluent-bit.conf \
    /fluent-bit-3.2.2/conf/parsers.conf \
    /fluent-bit-3.2.2/conf/parsers_ambassador.conf \
    /fluent-bit-3.2.2/conf/parsers_java.conf \
    /fluent-bit-3.2.2/conf/parsers_extra.conf \
    /fluent-bit-3.2.2/conf/parsers_openstack.conf \
    /fluent-bit-3.2.2/conf/parsers_cinder.conf \
    /fluent-bit-3.2.2/conf/plugins.conf \
    /fluent-bit/etc/

EXPOSE 2020

ENTRYPOINT ["/usr/local/bin/fluent-bit"]
CMD ["/usr/local/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
