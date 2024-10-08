FROM postgres:alpine AS postgresql

FROM redis:alpine AS redis

FROM clickhouse/clickhouse-server:head-alpine AS clickhouse

FROM alpine:latest

RUN apk add --no-cache \
    bash \
    curl \
    jq \
    mongodb-tools \
    libpq \
    lz4-libs \
    aws-cli

COPY --from=postgresql /usr/local/bin/pg_dumpall /usr/local/bin/pg_dumpall
COPY --from=postgresql /usr/local/bin/pg_dump /usr/local/bin/pg_dump
COPY --from=redis /usr/local/bin/redis-cli /usr/local/bin/redis-cli

COPY docker/backup /scripts

ENTRYPOINT ["/scripts/backup.sh"]
