FROM redis:latest

COPY entrypoint.sh /scuffle-entrypoint.sh

ENTRYPOINT [ "/scuffle-entrypoint.sh", "/data/docker-entrypoint.sh" ]
