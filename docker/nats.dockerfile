FROM nats:alpine

RUN apk add --no-cache bash

COPY docker/entrypoint.sh /scuffle-entrypoint.sh

ENTRYPOINT [ "/scuffle-entrypoint.sh", "docker-entrypoint.sh" ]
CMD [ "nats-server", "--config", "/etc/nats/nats-server.conf" ]
