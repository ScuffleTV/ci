# syntax = docker/dockerfile:1.4
ARG BASE_IMAGE=ubuntu:lunar

FROM $BASE_IMAGE

LABEL org.opencontainers.image.source=https://github.com/scuffletv/ci
LABEL org.opencontainers.image.description="Build for ScuffleTV"
LABEL org.opencontainers.image.licenses=MIT

ENV CARGO_HOME=/usr/local/cargo \
    RUSTUP_HOME=/usr/local/rustup \
    PATH=/usr/local/cargo/bin:/usr/local/pnpm/bin:$PATH

ARG RUST_VERSION=1.74.0
ARG NODE_MAJOR=20
ARG WASM_BINDGEN_VERSION=116
ARG PROTOBUF_VERSION=v25.1

RUN <<eot
    set -eux

    apt-get update
    apt-get install -y --no-install-recommends \
            tar \
            clang \
            lld \
            make \
            dpkg-dev \
            zip \
            unzip \
            curl \
            wget \
            git \
            ssh \
            ca-certificates \
            pkg-config \
            gnupg2 \
            cmake \
            clang-format \
            ninja-build \
            libssl-dev \
            ffmpeg

    # We want to symlink clang-17 to clang and cc so that we can use it as a drop in replacement for gcc
    touch /usr/bin/cc  && mv /usr/bin/cc /usr/bin/cc.bak
    touch /usr/bin/c++ && mv /usr/bin/c++ /usr/bin/c++.bak
    touch /usr/bin/gcc && mv /usr/bin/gcc /usr/bin/gcc.bak
    touch /usr/bin/g++ && mv /usr/bin/g++ /usr/bin/g++.bak

    ln -s $(which clang) /usr/bin/cc
    ln -s $(which clang) /usr/bin/gcc
    ln -s $(which clang++) /usr/bin/c++
    ln -s $(which clang++) /usr/bin/g++

    touch /usr/bin/ld && mv /usr/bin/ld /usr/bin/ld.bak
    ln -s $(which lld) /usr/bin/ld

    # Compile protobuf
    git clone https://github.com/protocolbuffers/protobuf.git -b $PROTOBUF_VERSION /tmp/protobuf --depth 1 --recurse-submodules
    mkdir /tmp/protobuf/build
    cd /tmp/protobuf/build
    cmake -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -GNinja ..
    cmake --build . --target install -j $(nproc) --config Release
    ldconfig
    cd -
    rm -rf /tmp/protobuf

    mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list

    apt-get update
    apt-get install -y nodejs --no-install-recommends

    npm install -g pnpm

    # Install Rust
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain=$RUST_VERSION

    # Install Rust tools
    rustup update
    rustup target add wasm32-unknown-unknown
    rustup component add clippy rustfmt llvm-tools-preview

    cargo install sqlx-cli --features rustls,postgres --no-default-features
    cargo install cargo-llvm-cov
    cargo install cargo-nextest
    cargo install mask
    cargo install cargo-sweep
    cargo install wasm-bindgen-cli

    # Install Wasm tools
    wget https://github.com/WebAssembly/binaryen/releases/download/version_$WASM_BINDGEN_VERSION/binaryen-version_$WASM_BINDGEN_VERSION-x86_64-linux.tar.gz -O /tmp/binaryen.tar.gz
    tar -xvf /tmp/binaryen.tar.gz -C /tmp
    mv /tmp/binaryen-version_$WASM_BINDGEN_VERSION/bin/* /usr/local/bin/
    rm -rf /tmp/binaryen.tar.gz /tmp/binaryen-version_$WASM_BINDGEN_VERSION

    # Clean up
    rm -rf /usr/local/cargo/registry /usr/local/cargo/git 
    apt-get autoremove -y
    apt-get clean
    rm -rf /var/lib/apt/lists/*

    # Remove SSH host keys, for some reason they are generated on build.
    rm -rf /etc/ssh/ssh_host_* 
eot
