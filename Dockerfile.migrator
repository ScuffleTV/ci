FROM rust:alpine as builder

LABEL org.opencontainers.image.source=https://github.com/scuffletv/ci
LABEL org.opencontainers.image.description="Migrator for ScuffleTV"
LABEL org.opencontainers.image.licenses=BSD-4-Clause

RUN apk add --no-cache musl-dev openssl-dev perl make && \
    cargo install --git https://github.com/launchbadge/sqlx sqlx-cli --features openssl-vendored

FROM alpine:latest

COPY --from=builder /usr/local/cargo/bin/sqlx /usr/local/bin/sqlx

ENTRYPOINT ["sh"]
