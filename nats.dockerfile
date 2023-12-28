FROM nats:latest

COPY entrypoint.sh /scuffle-entrypoint.sh

ENTRYPOINT [ "/scuffle-entrypoint.sh", "/nats-server" ]
