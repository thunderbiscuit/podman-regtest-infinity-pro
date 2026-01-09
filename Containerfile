FROM debian:bookworm

# Install wget dependency
RUN apt-get update && apt-get install -y wget

# Setup bitcoin core binaries download
ARG BITCOIN_VERSION
ARG TARGET_ARCH
ENV BITCOIN_TARBALL=bitcoin-${BITCOIN_VERSION}-${TARGET_ARCH}.tar.gz
ENV BITCOIN_URL=https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/${BITCOIN_TARBALL}

# Install bitcoin core
RUN wget ${BITCOIN_URL} \
    && tar -xzvf ${BITCOIN_TARBALL} -C /opt \
    && rm ${BITCOIN_TARBALL} \
    && ln -s /opt/bitcoin-${BITCOIN_VERSION}/bin/* /usr/local/bin/

# Install dependencies for Esplora
RUN apt-get update && apt-get install -y \
    curl \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libclang-dev \
    netcat-openbsd \
    nano \
    && rm -rf /var/lib/apt/lists/*

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.92.0
# Set the environment variable so that Cargo is in PATH
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup default 1.92.0

# Build Esplora and Electrum services
WORKDIR /root/electrs/
RUN rustup update
RUN git clone https://github.com/Blockstream/electrs.git .
RUN git checkout new-index
RUN cargo build --release

# Build Fast Bitcoin Block Explorer
WORKDIR /root/fbbe/
RUN git clone https://github.com/RCasatta/fbbe .
RUN cargo build --release

COPY start-services.sh /usr/local/bin/
ENTRYPOINT ["start-services.sh"]
