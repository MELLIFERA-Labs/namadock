FROM lukemathwalker/cargo-chef:latest-rust-1.85.1-bookworm AS chef

WORKDIR /src

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    clang-tools-14 \
    git \
    libssl-dev \
    pkg-config \
    protobuf-compiler \
    libudev-dev \
    libprotobuf-dev \ 
    && rm -rf /var/lib/apt/lists/*
    
# ------ SOURCES STAGE --------------------------
FROM chef AS source
ARG NAMADA_VERSION=main

RUN git clone --depth 1 --branch ${NAMADA_VERSION} https://github.com/namada-net/namada.git .

# --------------------------PLANNER STAGE--------------------------

FROM chef AS planner
WORKDIR /src

COPY --from=source /src/ . 

RUN cargo chef prepare --recipe-path recipe.json
# --------------------------DEPS STAGE--------------------------
FROM chef AS deps

COPY --from=planner /src/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json 

# -------------------------- BUILDER STAGE--------------------------

FROM chef AS builder 
COPY --from=source /src/  /src  
# re-use deps
COPY --from=deps /src/target /src/target
COPY --from=deps /usr/local/cargo /usr/local/cargo
# build application
RUN make build-release JOBS=$(nproc)

FROM golang:1.21.0 AS tendermint-builder
WORKDIR /app

RUN git clone -b v0.37.15 --single-branch https://github.com/cometbft/cometbft.git && cd cometbft && make build

FROM debian:bookworm-slim AS runtime

ENV NAMADA_LOG_COLOR=false

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libcurl4-openssl-dev \
        curl \
        jq \
        lz4 \ 
        libudev-dev \
        ca-certificates \        
        gosu \
        python3 python3-pip python3-venv pipx \ 
    && rm -rf /var/lib/apt/lists/*



RUN useradd -m --uid 1000 --user-group namada
ENV PIPX_BIN_DIR=/usr/local/bin

RUN pipx install --pip-args="--no-cache-dir" "ansible-core==2.18.6"

RUN ansible --version 
RUN ansible-galaxy collection install community.general

COPY --from=builder /src/target/release/namada   /usr/local/bin/
COPY --from=builder /src/target/release/namadan  /usr/local/bin/
COPY --from=builder /src/target/release/namadaw  /usr/local/bin/
COPY --from=builder /src/target/release/namadac  /usr/local/bin/
COPY --from=tendermint-builder --chmod=0755 /app/cometbft/build/cometbft /usr/local/bin

COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY ansible/ /ansible/

EXPOSE 26656 26657 26659 26660 26658

RUN mkdir -p /home/namada/.local/share/namada

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]