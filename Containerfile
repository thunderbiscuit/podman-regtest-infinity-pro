# =============================================================================
# BUILDER STAGE
# =============================================================================
FROM debian:bookworm AS builder

# Install all build dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libclang-dev \
    && rm -rf /var/lib/apt/lists/*

# Download Bitcoin Core (currently defaults to 29.2)
ARG BITCOIN_VERSION=29.2
ARG TARGET_ARCH
ENV BITCOIN_TARBALL=bitcoin-${BITCOIN_VERSION}-${TARGET_ARCH}.tar.gz
ENV BITCOIN_URL=https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/${BITCOIN_TARBALL}

RUN wget ${BITCOIN_URL} \
    && tar -xzvf ${BITCOIN_TARBALL} -C /opt \
    && rm ${BITCOIN_TARBALL}

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.92.0
ENV PATH="/root/.cargo/bin:${PATH}"

# Build electrs (pinned to new-index branch commit, Jan 2026)
# Clean up build artifacts in same layer to save disk space during build
ENV ELECTRS_COMMIT=e60ca890959b2cb9b62d5253ffa0cf4b25b144eb
WORKDIR /root/electrs
RUN git clone https://github.com/Blockstream/electrs.git . && git checkout ${ELECTRS_COMMIT}
RUN cargo build --release \
    && strip target/release/electrs \
    && mv target/release/electrs /usr/local/bin/ \
    && rm -rf target .git

# Build fbbe (pinned to commit, Jan 2026)
ENV FBBE_COMMIT=6e6b8f60d66b2b34d66282ce4982a20db4c53c27
WORKDIR /root/fbbe
RUN git clone https://github.com/RCasatta/fbbe . && git checkout ${FBBE_COMMIT}
RUN cargo build --release \
    && strip target/release/fbbe \
    && mv target/release/fbbe /usr/local/bin/ \
    && rm -rf target .git

# =============================================================================
# RUNTIME STAGE
# =============================================================================
FROM debian:bookworm-slim

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3 \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Copy Bitcoin Core binaries
ARG BITCOIN_VERSION=29.2
COPY --from=builder /opt/bitcoin-${BITCOIN_VERSION}/bin/* /usr/local/bin/

# Copy the Rust binaries
COPY --from=builder /usr/local/bin/electrs /usr/local/bin/
COPY --from=builder /usr/local/bin/fbbe /usr/local/bin/

# Copy startup script
COPY start-services.sh /usr/local/bin/

ENTRYPOINT ["start-services.sh"]
