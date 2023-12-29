set -eux

apt-get update
apt-get install -y --no-install-recommends \
        tar \
        clang \
        lld \
        make \
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
        nasm \
        yasm \
        meson \
        libtool \
        autoconf \
        automake \
        build-essential \
        libssl-dev

# Install all external libraries
git clone https://github.com/ScuffleTV/external.git --depth 1 --recurse-submodule --shallow-submodules /tmp/external
/tmp/external/build.sh --prefix /usr/local --build "all ffmpeg+tls"
ldconfig
rm -rf /tmp/external

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
rustup toolchain install nightly

rustup +nightly component add clippy
rustup +nightly component add rustfmt

rustup target add wasm32-unknown-unknown
rustup component add clippy rustfmt llvm-tools-preview

cargo install sqlx-cli --features rustls,postgres --no-default-features
cargo install cargo-llvm-cov
cargo install cargo-nextest
cargo install mask
cargo install cargo-sweep
cargo install wasm-bindgen-cli

# Install Wasm tools
ARCH=$(uname -m)
wget https://github.com/WebAssembly/binaryen/releases/download/version_$WASM_BINDGEN_VERSION/binaryen-version_$WASM_BINDGEN_VERSION-$ARCH-linux.tar.gz -O /tmp/binaryen.tar.gz
tar -xvf /tmp/binaryen.tar.gz -C /tmp
mv /tmp/binaryen-version_$WASM_BINDGEN_VERSION/bin/* /usr/local/bin/
rm -rf /tmp/binaryen.tar.gz /tmp/binaryen-version_$WASM_BINDGEN_VERSION

# Clean up
rm -rf /usr/local/cargo/registry /usr/local/cargo/git 
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /root/.npm

# Remove SSH host keys, for some reason they are generated on build.
rm -rf /etc/ssh/ssh_host_*
