# Bitcoin Core version, shared by both stages (override with --build-arg)
ARG BITCOIN_VERSION=31.0

# =============================================================================
# BUILDER STAGE
# =============================================================================
FROM debian:trixie AS builder

# Install all build dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    git \
    build-essential \
    cmake \
    pkg-config \
    libssl-dev \
    libclang-dev \
    && rm -rf /var/lib/apt/lists/*

# Download Bitcoin Core (currently defaults to 31.0)
ARG BITCOIN_VERSION
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

# Build bitcoin-tui (pinned to v0.8.3 release commit, Apr 2026)
# Only the main target is built; the test targets are skipped
ENV BITCOIN_TUI_COMMIT=e4300eed8e7789a4d8ca3ba3acd8de95ccd3661f
WORKDIR /root/bitcoin-tui
RUN git clone https://github.com/janb84/bitcoin-tui.git . && git checkout ${BITCOIN_TUI_COMMIT}
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release \
    && cmake --build build --target bitcoin-tui -j$(nproc) \
    && strip build/bin/bitcoin-tui \
    && mv build/bin/bitcoin-tui /usr/local/bin/ \
    && rm -rf build .git

# =============================================================================
# RUNTIME STAGE
# =============================================================================
FROM debian:trixie-slim

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libssl3t64 \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

ARG BITCOIN_VERSION
COPY --from=builder /opt/bitcoin-${BITCOIN_VERSION}/bin/* /usr/local/bin/

# Copy the Rust binaries
COPY --from=builder /usr/local/bin/electrs /usr/local/bin/
COPY --from=builder /usr/local/bin/fbbe /usr/local/bin/

# Copy the bitcoin-tui binary
COPY --from=builder /usr/local/bin/bitcoin-tui /usr/local/bin/

# Copy startup script
COPY start-services.sh /usr/local/bin/

ENTRYPOINT ["start-services.sh"]
